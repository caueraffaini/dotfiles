#!/usr/bin/env bash
# Dotfiles drift detector. Two checks, notify only when drift is found
# (silent when clean — matches the Waybar backup module philosophy).
#
#   1. Link integrity: every tracked file in ~/dotfiles/<pkg> must be
#      reachable at its stow target and canonically resolve back to the
#      same repo file. Stow folds directories, so the symlink is often a
#      parent dir, not the file — hence we compare resolved real paths,
#      not the -L bit. Catches a target gone missing or a stow package
#      unfolded into a separate real copy that has since diverged.
#   2. Uncommitted state: `git status --porcelain` on ~/dotfiles non-empty
#      means repo and live system have drifted from the committed source.
#
# Runs on the host via the user systemd timer. Plain host paths.
set -uo pipefail

DOTFILES="$HOME/dotfiles"
broken=()
detached=()

# Packages whose stow target is NOT $HOME (root/Flatpak), skip symlink walk:
#   firefox  -> manual symlinks into the Flatpak profile (not stow)
#   greetd   -> /etc/greetd (root target)
SKIP_PKGS="firefox greetd"

for pkgdir in "$DOTFILES"/*/; do
    pkg=$(basename "$pkgdir")
    [[ " $SKIP_PKGS " == *" $pkg "* ]] && continue
    [[ "$pkg" == .git ]] && continue

    while IFS= read -r -d '' f; do
        rel=${f#"$pkgdir"}                 # path relative to package root
        # Stow's built-in ignore list — these never get symlinked.
        case "$(basename "$f")" in
            .gitignore|.stow-local-ignore|README*|LICENSE*|.git) continue ;;
            lazy-lock.json) continue ;;  # gitignored, per-machine churn
        esac
        target="$HOME/$rel"                # stow maps <pkg>/<rel> -> ~/<rel>
        if [[ ! -e "$target" ]]; then
            broken+=("$rel")               # target missing entirely
        elif [[ "$(readlink -f "$target")" != "$(readlink -f "$f")" ]]; then
            detached+=("$rel")             # resolves to a different real file
        fi
    done < <(find "$pkgdir" -type f -not -path '*/.git/*' -print0)
done

uncommitted=$(git -C "$DOTFILES" status --porcelain 2>/dev/null | wc -l)

if (( ${#broken[@]} == 0 && ${#detached[@]} == 0 && uncommitted == 0 )); then
    exit 0                                 # clean — stay silent
fi

msg=""
(( ${#broken[@]}    )) && msg+="${#broken[@]} not symlinked (real file / missing): ${broken[*]:0:5}\n"
(( ${#detached[@]}  )) && msg+="${#detached[@]} symlink wrong target: ${detached[*]:0:5}\n"
(( uncommitted      )) && msg+="${uncommitted} uncommitted/untracked in ~/dotfiles\n"

/usr/bin/notify-send -u normal "Dotfiles drift" "$(printf '%b' "$msg")"
