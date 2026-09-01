#!/usr/bin/env bash
# Waybar system-health aggregator. Surfaces box-level problems in ONE collapsed
# module. Reads LOCAL systemd state + a local git status only — never restic,
# rclone or any network/Drive call (would spend the shared API quota that the
# backup design protects). Mirrors the backup.sh / snapshots.sh idiom.
#
# Anti-pollution contract:
#   - all-OK  -> {"text":""}            (module collapses, invisible)
#   - warn    -> one 󰀪 glyph, br-orange (user-actionable regressions)
#   - critical-> one 󰀦 glyph, br-red    (a protective service has failed)
# Detail is tooltip-only; highest active severity picks the glyph/class.
# Click target = sysmenu (rofi system-actions sheet).

DOTFILES="${HOME}/dotfiles"

crit=()   # critical lines (a guarantee broke)
warn=()   # warn lines     (a setting regressed / drifted)

# Read-only, all local. Timestamps hold spaces — always --value per property.
ush() { /usr/bin/systemctl --user show "$1" --value -p "$2" 2>/dev/null; }
ssh_() { /usr/bin/systemctl        show "$1" --value -p "$2" 2>/dev/null; }

# A user oneshot/service counts as failed if it's in the failed state, or it
# finished with a non-success Result (matches backup.sh's failure test).
svc_failed() {
    local s; s=$(ush "$1" ActiveState)
    local r; r=$(ush "$1" Result)
    [[ "$s" == "failed" ]] && return 0
    [[ -n "$r" && "$r" != "success" ]] && return 0
    return 1
}

# 1. restic backup — the protective job. Failure = backups not happening.
svc_failed restic-backup.service && \
    crit+=("restic-backup FAILED — journalctl --user -u restic-backup")

# 2. restic verify — repo integrity check (monthly).
svc_failed restic-verify.service && \
    crit+=("restic-verify FAILED — journalctl --user -u restic-verify")

# 3. btrfs monthly scrub (system unit). success even when never-run/inactive;
#    only a real non-success Result is a problem.
scrub_r=$(ssh_ 'btrfs-scrub@-.service' Result)
[[ -n "$scrub_r" && "$scrub_r" != "success" ]] && \
    crit+=("btrfs-scrub Result=${scrub_r} — sudo btrfs scrub status /")

# 4. cpupower.service regression (C1 disabled it; it fights ppd if re-enabled).
[[ "$(/usr/bin/systemctl is-enabled cpupower.service 2>/dev/null)" == "enabled" ]] && \
    warn+=("cpupower.service re-enabled — fights power-profiles-daemon (C1)")

# 5. dotfiles drift: local git only (no symlink walk — dotfiles-drift.timer
#    owns the deep check; this is the cheap, most-common signal).
if command -v git >/dev/null 2>&1; then
    n=$(git -C "$DOTFILES" status --porcelain 2>/dev/null | /usr/bin/grep -c .)
    (( n > 0 )) && warn+=("${n} uncommitted/untracked in ~/dotfiles")
fi

# Compose. Critical wins the glyph; tooltip lists every active issue.
issues=("${crit[@]}" "${warn[@]}")
if (( ${#issues[@]} == 0 )); then
    printf '{"text":""}\n'                       # healthy → collapsed/hidden
    exit 0
fi

tip=$(printf '%s\\n' "${issues[@]}")
tip=${tip%\\n}                                    # strip trailing newline

if (( ${#crit[@]} > 0 )); then
    printf '{"text":"󰀦","tooltip":"%s","class":"critical"}\n' "$tip"
else
    printf '{"text":"󰀪","tooltip":"%s","class":"warn"}\n' "$tip"
fi
