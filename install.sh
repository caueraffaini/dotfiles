#!/usr/bin/env bash
# Dotfiles installer — GNU Stow management harness.
#
# Usage:
#   ./install.sh [options] [command] [package|profile...]
#
# Commands:
#   stow (default)             Deploy/symlink selected package(s)
#   -R, --restow, restow       Re-link package(s) and prune dead links
#   -D, --delete, unstow       Remove symlinks for selected package(s)
#
# Options:
#   -n, --simulate, --dry-run  Dry run, link nothing
#   -b, --backup               Automatically back up conflicting files (*.dotfiles.bak.<timestamp>)
#   -h, --help                 Display this help message
#
# Profiles / Groups:
#   --all                      All user packages + Flatpak Firefox (default)
#   --core                     Shell, scripts, package managers, baseline configs
#   --wm                       Hyprland, Waybar, Rofi, SwayNC, Ghostty
#   --media                    MPV, Spotify-Player, Zathura, MangoHud, GameMode
#   --apps                     Neovim, Yazi, Firefox
#   --system                   Root-target packages (greetd)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Opt-in pre-push validation gate (A3a): point git at the tracked hook dir idempotently
if [[ -d "$REPO/.githooks" ]] \
   && [[ "$(git -C "$REPO" config --local --get core.hooksPath 2>/dev/null)" != ".githooks" ]]; then
  git -C "$REPO" config --local core.hooksPath .githooks 2>/dev/null \
    && echo ">> enabled pre-push gate (core.hooksPath=.githooks)" || true
fi

STOW_CMD=(stow)
STOW() { "${STOW_CMD[@]}" "$@"; }

# Package Groups
GRP_CORE=(ai-rules dotfiles-drift gemini gtk paru scripts theme zsh)
GRP_WM=(ghostty hypr rofi swaync waybar)
GRP_MEDIA=(gamemode mangohud mpv spotify-player zathura)
GRP_APPS=(nvim yazi)
GRP_SPECIAL=(firefox greetd)

USER_STD_PKGS=("${GRP_CORE[@]}" "${GRP_WM[@]}" "${GRP_MEDIA[@]}" "${GRP_APPS[@]}")
ALL_PKGS=("${USER_STD_PKGS[@]}" "${GRP_SPECIAL[@]}")

MODE=stow
SIMULATE=()
DRY=0
BACKUP=0
declare -a SELECTED=()
declare -a STOWED=() SKIPPED=()

die()  { echo "error: $*" >&2; exit 1; }
note() { echo ">> $*"; }

is_pkg() {
  local p
  for p in "${ALL_PKGS[@]}"; do [[ $p == "$1" ]] && return 0; done
  return 1
}

backup_conflicts() {
  local pkg="$1"
  local target_base="$HOME"
  [[ "$pkg" == "greetd" ]] && target_base="/"

  # Check conflicts via dry run output
  local conflict_output
  conflict_output=$(STOW -n -v -d "$REPO" -t "$target_base" "$MODE_FLAG" "$pkg" 2>&1 || true)
  
  if echo "$conflict_output" | grep -q "existing target"; then
    local ts
    ts="$(date +%Y%m%d%H%M%S)"
    while IFS= read -r line; do
      if [[ $line =~ cannot\ stow\ .*over\ existing\ target\ (.+)\ since ]]; then
        local conflict_rel="${BASH_REMATCH[1]}"
        local full_conflict_path="$target_base/$conflict_rel"
        if [[ -e "$full_conflict_path" && ! -L "$full_conflict_path" ]]; then
          local bak_path="${full_conflict_path}.dotfiles.bak.${ts}"
          if [[ $DRY -eq 1 ]]; then
            echo "   [backup] would move $full_conflict_path -> $bak_path"
          else
            echo "   [backup] backing up $full_conflict_path -> $bak_path"
            mv "$full_conflict_path" "$bak_path"
          fi
        fi
      fi
    done <<< "$conflict_output"
  fi
}

stow_std() {
  local pkg="$1"
  if [[ $BACKUP -eq 1 && $MODE != delete ]]; then
    backup_conflicts "$pkg"
  fi

  if STOW "${SIMULATE[@]}" -v -d "$REPO" -t "$HOME" "$MODE_FLAG" "$pkg" 2>&1 \
       | sed 's/^/   /'; then
    STOWED+=("$pkg")
  else
    SKIPPED+=("$pkg")
    echo "   !! '$pkg' had conflicts (see above). Run with -b/--backup to auto-backup." >&2
  fi
}

greetd_install() {
  note "greetd -> /etc/greetd (root target, needs sudo)"
  if [[ $DRY -eq 1 ]]; then
    STOW -n -v -d "$REPO" -t / "$MODE_FLAG" greetd 2>&1 | sed 's/^/   /' || true
    STOWED+=("greetd(dry)")
    return
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    note "sudo not found — skipping greetd"; SKIPPED+=("greetd"); return
  fi
  if [[ $BACKUP -eq 1 && $MODE != delete ]]; then
    backup_conflicts "greetd"
  fi
  if sudo "${STOW_CMD[@]}" -v -d "$REPO" -t / "$MODE_FLAG" greetd 2>&1 | sed 's/^/   /'; then
    STOWED+=("greetd")
  else
    SKIPPED+=("greetd")
  fi
}

firefox_install() {
  local ff_root="$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
  note "firefox -> Flatpak profile (manual symlinks, not stow)"

  if [[ ! -d $ff_root ]]; then
    note "Firefox Flatpak profile not found ($ff_root)."
    note "Run Firefox once, then: ./install.sh firefox"
    SKIPPED+=("firefox"); return
  fi

  local ff_profile=""
  if [[ -f "$ff_root/profiles.ini" ]]; then
    local prof_rel
    prof_rel="$(grep -E '^Path=' "$ff_root/profiles.ini" | head -n 1 | cut -d= -f2)"
    if [[ -n "$prof_rel" && -d "$ff_root/$prof_rel" ]]; then
      ff_profile="$ff_root/$prof_rel"
    fi
  fi
  if [[ -z "$ff_profile" && -f "$REPO/firefox/profiles.ini" ]]; then
    local prof_rel
    prof_rel="$(grep -E '^Path=' "$REPO/firefox/profiles.ini" | head -n 1 | cut -d= -f2)"
    if [[ -n "$prof_rel" && -d "$ff_root/$prof_rel" ]]; then
      ff_profile="$ff_root/$prof_rel"
    fi
  fi
  if [[ -z "$ff_profile" ]]; then
    ff_profile="$(find "$ff_root" -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -n 1)"
  fi
  if [[ -z "$ff_profile" ]]; then
    ff_profile="$(find "$ff_root" -maxdepth 1 -type d -name "*default*" 2>/dev/null | head -n 1)"
  fi

  if [[ -z "$ff_profile" ]]; then
    note "No Firefox profile directory found under $ff_root."
    note "Run Firefox once, then: ./install.sh firefox"
    SKIPPED+=("firefox"); return
  fi

  if [[ $MODE == delete ]]; then
    if [[ $DRY -eq 1 ]]; then
      note "would rm firefox symlinks under $ff_root"
      STOWED+=("firefox(dry)")
      return
    fi
    rm -f "$ff_root/profiles.ini" "$ff_profile/user.js" \
          "$ff_profile/chrome/userChrome.css"
    STOWED+=("firefox")
    return
  fi

  local -a links=()
  if [[ -f "$REPO/firefox/profiles.ini" && ! -e "$ff_root/profiles.ini" && ! -L "$ff_root/profiles.ini" ]]; then
    links+=("$REPO/firefox/profiles.ini|$ff_root/profiles.ini")
  fi
  if [[ -f "$REPO/firefox/default-release/user.js" ]]; then
    links+=("$REPO/firefox/default-release/user.js|$ff_profile/user.js")
  fi
  if [[ -f "$REPO/firefox/default-release/chrome/userChrome.css" ]]; then
    if [[ ! -L "$ff_profile/chrome" ]]; then
      links+=("$REPO/firefox/default-release/chrome/userChrome.css|$ff_profile/chrome/userChrome.css")
    fi
  fi

  local pair src dst
  for pair in "${links[@]}"; do
    src="${pair%%|*}"; dst="${pair#*|}"
    if [[ $DRY -eq 1 ]]; then
      echo "   would link $dst -> $src"
    else
      if [[ -e "$dst" && ! -L "$dst" && $BACKUP -eq 1 ]]; then
        local ts
        ts="$(date +%Y%m%d%H%M%S)"
        mv "$dst" "${dst}.dotfiles.bak.${ts}"
      fi
      mkdir -p "$(dirname "$dst")"
      ln -sfn "$src" "$dst"
      echo "   linked $dst -> $src"
    fi
  done
  local tag=""
  [[ $DRY -eq 1 ]] && tag="(dry)"
  STOWED+=("firefox$tag")
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    stow)          MODE=stow ;;
    -R|--restow|restow) MODE=restow ;;
    -D|--delete|--unstow|unstow|delete) MODE=delete ;;
    -n|--simulate|--dry-run) DRY=1; SIMULATE=(-n) ;;
    -b|--backup)   BACKUP=1 ;;
    --all)         SELECTED+=("${USER_STD_PKGS[@]}" firefox) ;;
    --core)        SELECTED+=("${GRP_CORE[@]}") ;;
    --wm)          SELECTED+=("${GRP_WM[@]}") ;;
    --media)       SELECTED+=("${GRP_MEDIA[@]}") ;;
    --apps)        SELECTED+=("${GRP_APPS[@]}" firefox) ;;
    --theme)       SELECTED+=(theme) ;;
    --system)      SELECTED+=(greetd) ;;
    -h|--help)
      sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
      exit 0
      ;;
    -*)            die "unknown flag: $1" ;;
    *)
      if is_pkg "$1"; then
        SELECTED+=("$1")
      else
        die "unknown package or option: $1"
      fi
      ;;
  esac
  shift
done

case "$MODE" in
  stow)   MODE_FLAG=-S ;;
  restow) MODE_FLAG=-R ;;
  delete) MODE_FLAG=-D ;;
esac

STOW --version >/dev/null 2>&1 || die "GNU Stow not installed (paru -S stow)"

# Default selection: user packages + firefox (greetd is opt-in via --system or explicit argument)
if [[ ${#SELECTED[@]} -eq 0 ]]; then
  [[ $MODE == delete ]] && die "--delete / unstow requires explicit package names or profiles"
  SELECTED=("${USER_STD_PKGS[@]}" firefox)
fi

# Remove duplicates while preserving order
declare -a UNIQUE_SELECTED=()
for item in "${SELECTED[@]}"; do
  skip=0
  for u in "${UNIQUE_SELECTED[@]:-}"; do
    if [[ "$u" == "$item" ]]; then skip=1; break; fi
  done
  [[ $skip -eq 0 ]] && UNIQUE_SELECTED+=("$item")
done

for pkg in "${UNIQUE_SELECTED[@]}"; do
  case "$pkg" in
    greetd)  greetd_install ;;
    firefox) firefox_install ;;
    *)       note "$pkg ($MODE)"; stow_std "$pkg" ;;
  esac
done

# Post-stow automatic theme synchronization if not dry run
if [[ $DRY -eq 0 && $MODE != delete ]]; then
  if [[ -f "$REPO/theme/.config/theme/render-theme.py" ]]; then
    python3 "$REPO/theme/.config/theme/render-theme.py" 2>/dev/null || true
  fi
fi

echo
echo "done ($MODE). ok: ${STOWED[*]:-none} | skipped: ${SKIPPED[*]:-none}"
