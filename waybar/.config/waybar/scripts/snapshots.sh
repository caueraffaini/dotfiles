#!/usr/bin/env bash
# Waybar Btrfs snapshot health indicator. Reads LOCAL snapper state only
# (no sudo — user in wheel group; no btrfs/disk calls). Hidden when healthy;
# warns only when the snapshot system looks broken:
#   - zero snapshots in the root config, OR
#   - newest snapshot older than STALE_H hours (timeline is hourly +
#     snap-pac fires on every pacman txn, so a long gap = broken).
# Glyph carries state; no color CSS (matches custom/backup decision).
STALE_H=48
CFG=root

# Snapshot numbers, machine-readable, no sudo.
nums=$(/usr/bin/snapper -c "$CFG" --csvout list --columns number 2>/dev/null \
        | /usr/bin/grep -E '^[0-9]+$')
count=$(printf '%s\n' "$nums" | /usr/bin/grep -c .)

if (( count == 0 )); then
    printf '{"text":"󰕌","tooltip":"Snapshots: NONE in \"%s\" config — snapper/timeline broken","class":"warn"}\n' "$CFG"
    exit 0
fi

# Newest snapshot date (last data row of the date column).
newest=$(/usr/bin/snapper -c "$CFG" --csvout list --columns date 2>/dev/null \
          | /usr/bin/tail -1)

if ts=$(/usr/bin/date -d "$newest" +%s 2>/dev/null); then
    age_h=$(( ( $(/usr/bin/date +%s) - ts ) / 3600 ))
    if (( age_h >= STALE_H )); then
        printf '{"text":"󰕌","tooltip":"Snapshots: newest is %dh old (%d total) — timeline stalled","class":"warn"}\n' "$age_h" "$count"
        exit 0
    fi
fi

# Healthy → empty text collapses the module (hidden), like custom/backup.
printf '{"text":""}\n'
