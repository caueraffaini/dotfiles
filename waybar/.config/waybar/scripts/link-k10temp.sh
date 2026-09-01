#!/usr/bin/env bash
set -euo pipefail

# Find hwmon path for k10temp
# /sys/class/hwmon/hwmon*/name contains the driver name
K10TEMP_PATH=$(grep -l "k10temp" /sys/class/hwmon/hwmon*/name 2>/dev/null | head -n 1 | xargs -r dirname)

if [[ -z "$K10TEMP_PATH" ]]; then
    echo "k10temp not found" >&2
    exit 1
fi

RUNDIR="${XDG_RUNTIME_DIR:-/tmp/runtime-${UID:-$(id -u)}}"
mkdir -p "$RUNDIR"
chmod 700 "$RUNDIR" 2>/dev/null || true
ln -sfn "$K10TEMP_PATH" "$RUNDIR/waybar-k10temp"

CFG_DIR="$HOME/.config/waybar"
if [[ -d "$CFG_DIR" ]]; then
    ln -sfn "$K10TEMP_PATH" "$CFG_DIR/k10temp"
fi

