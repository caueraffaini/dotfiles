#!/usr/bin/env bash

# Power profile menu for Waybar + Rofi
# This script is executed by Waybar on the HOST.
# Use host-native binary paths.

PPCTL="/usr/bin/powerprofilesctl"
ROFI="/usr/bin/rofi"

declare -A ICONS
ICONS=( ["performance"]="" ["balanced"]="" ["power-saver"]="" )

get_current() {
    $PPCTL get 2>/dev/null
}

show_menu() {
    MENU_OPTIONS=$($PPCTL list | grep -E '^[ *]+ [a-z-]+:' | sed -E 's/^[ *]+ //;s/://' | sort -u)
    CHOICE=$(echo -e "$MENU_OPTIONS" | $ROFI -dmenu -p "Power Profile" -i)
    if [ -n "$CHOICE" ]; then
        $PPCTL set "$CHOICE"
    fi
}

output_waybar() {
    CURRENT=$(get_current)
    ICON="${ICONS[$CURRENT]:-}"
    printf '{"text": "%s", "tooltip": "Profile: %s"}\n' "$ICON" "$CURRENT"
}

case $1 in
    --menu) show_menu ;;
    *) output_waybar ;;
esac
