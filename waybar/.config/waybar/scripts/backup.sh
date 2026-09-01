#!/usr/bin/env bash
# Waybar restic backup indicator. Reads LOCAL systemd state only — never calls
# restic/rclone (would spend the shared Google API quota the backup-fix protects).
# Hidden when healthy/idle; aqua while a run is active; red after a failure.
SVC="restic-backup.service"

# Read-only systemd queries, all local (timestamps contain spaces — read each
# property with --value, never eval the raw output).
sc() { /usr/bin/systemctl --user show "$SVC" --value -p "$1" 2>/dev/null; }
V_ActiveState=$(sc ActiveState)
V_Result=$(sc Result)
V_ExecMainExitTimestamp=$(sc ExecMainExitTimestamp)
V_ExecMainStartTimestamp=$(sc ExecMainStartTimestamp)

case "$V_ActiveState" in
    activating|active|reloading)
        tip="Restic backup running…"
        # Parse restic's local progress lines from the journal (no rclone/Drive
        # calls). Format: [M:SS] P.PP%  N files X.XXX GiB, total M files Y GiB
        if start=$(/usr/bin/date -d "$V_ExecMainStartTimestamp" +%s 2>/dev/null); then
            line=$(/usr/bin/journalctl --user -u restic-backup.service \
                    --since "@$start" -o cat 2>/dev/null \
                    | /usr/bin/grep -aE '^\[[0-9]+:[0-9]+\] +[0-9]' | tail -1)
            if [[ -n "$line" ]]; then
                el=$(printf '%s' "$line" | /usr/bin/sed -E 's/^\[([0-9]+:[0-9]+)\].*/\1/')
                pc=$(printf '%s' "$line" | /usr/bin/grep -oE '[0-9]+(\.[0-9]+)?%' | head -1)
                pc=${pc%%.*}; pc=${pc%\%}
                # done size is the one followed by a comma (before ", total")
                sz=$(printf '%s' "$line" | /usr/bin/sed -E 's/.* files +([0-9.]+ +[KMGT]i?B),.*/\1/')
                tip="Restic: ${pc}% · ${sz} · ${el}"
            fi
        fi
        printf '{"text":"󰑓","tooltip":"%s","class":"running"}\n' "$tip"
        exit 0
        ;;
esac

if [[ "$V_ActiveState" == "failed" || ( -n "$V_Result" && "$V_Result" != "success" ) ]]; then
    rel="unknown time"
    if [[ -n "$V_ExecMainExitTimestamp" ]]; then
        if ts=$(/usr/bin/date -d "$V_ExecMainExitTimestamp" +%s 2>/dev/null); then
            d=$(( $(/usr/bin/date +%s) - ts ))
            if   (( d < 3600 ));  then rel="$(( d / 60 ))m ago"
            elif (( d < 86400 )); then rel="$(( d / 3600 ))h ago"
            else                       rel="$(( d / 86400 ))d ago"
            fi
        fi
    fi
    printf '{"text":"󰀦","tooltip":"Restic backup FAILED %s — journalctl --user -u restic-backup","class":"failed"}\n' "$rel"
    exit 0
fi

# Healthy / idle / never-run → empty text collapses the module (hidden).
printf '{"text":""}\n'
