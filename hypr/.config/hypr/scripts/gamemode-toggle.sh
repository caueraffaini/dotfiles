#!/usr/bin/env bash
# gamemode-toggle — Toggle or set Hyprland gaming mode (disables Super key shortcuts)
# usage: gamemode-toggle.sh [on|off|toggle|status]
set -euo pipefail

ACTION="${1:-toggle}"

is_game_mode() {
    local submap
    submap=$(hyprctl submap 2>/dev/null | tr -d '[:space:]' || echo "")
    [[ "$submap" == "game" ]]
}

enable_game_mode() {
    if is_game_mode; then
        return 0
    fi
    hyprctl dispatch 'hl.dsp.submap("game")' >/dev/null 2>&1 || true
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Game Mode" -u normal "Game Mode Active" \
            "Super key shortcuts disabled. Press Super+Shift+G or Super+F1 to exit."
    fi
}

disable_game_mode() {
    if ! is_game_mode; then
        return 0
    fi
    hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1 || true
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Game Mode" -u low "Game Mode Disabled" \
            "Super key shortcuts restored."
    fi
}

case "$ACTION" in
    on|start|enable)
        enable_game_mode
        ;;
    off|stop|disable)
        disable_game_mode
        ;;
    status)
        if is_game_mode; then
            echo "active"
            exit 0
        else
            echo "inactive"
            exit 1
        fi
        ;;
    toggle)
        if is_game_mode; then
            disable_game_mode
        else
            enable_game_mode
        fi
        ;;
    *)
        echo "usage: gamemode-toggle.sh [on|off|toggle|status]" >&2
        exit 1
        ;;
esac
