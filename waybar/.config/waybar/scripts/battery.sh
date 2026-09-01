#!/usr/bin/env bash
BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
CONS="/sys/bus/platform/devices/VPC2004:00/conservation_mode"

capacity=$(cat "$BAT/capacity" 2>/dev/null || echo 0)
status=$(cat "$BAT/status" 2>/dev/null || echo Unknown)
cycles=$(cat "$BAT/cycle_count" 2>/dev/null || echo "?")
cons=$(cat "$CONS" 2>/dev/null || echo 0)

# Pick icon
ICONS=("" "" "" "" "")
idx=$(( capacity * 4 / 100 ))
[[ $idx -gt 4 ]] && idx=4
icon="${ICONS[$idx]}"

# Override for charging/plugged
if [[ "$status" == "Charging" ]]; then
    icon=""
    cls="charging"
elif [[ "$status" == "Full" ]]; then
    icon=""
    cls="plugged"
elif [[ $capacity -le 15 ]]; then
    cls="critical"
elif [[ $capacity -le 30 ]]; then
    cls="warning"
else
    cls="discharging"
fi

# Conservation
if [[ "$cons" == "1" ]]; then
    cons_line="Conservation: ON (60% limit) — right-click to disable"
    cls="$cls conservation"
else
    cons_line="Conservation: OFF (100% max) — right-click to enable"
fi

tooltip="Battery: ${capacity}%\nStatus: ${status}\nCycles: ${cycles}\n${cons_line}"
printf '{"text": "%s %d%%", "tooltip": "%s", "class": "%s"}\n' "$icon" "$capacity" "$tooltip" "$cls"
