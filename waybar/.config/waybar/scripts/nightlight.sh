#!/usr/bin/env bash
set -euo pipefail

CONF="$HOME/.config/nightlight.conf"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/nightlight.state"

# Default configuration values
NIGHTLIGHT_LAT="0.0"
NIGHTLIGHT_LON="0.0"
NIGHTLIGHT_TEMP_NIGHT="3000"
NIGHTLIGHT_TEMP_DAY="6500"
if [[ -f "$CONF" ]]; then
    # shellcheck source=/dev/null
    source "$CONF"
fi

get_state() {
    if ! pgrep -x wlsunset >/dev/null 2>&1; then
        echo "off"
        return
    fi
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "auto"
    fi
}

notify_waybar() {
    pkill -RTMIN+9 waybar 2>/dev/null || true
}

start_auto() {
    pkill -x wlsunset 2>/dev/null || true
    sleep 0.1
    nohup wlsunset \
        -l "${NIGHTLIGHT_LAT}" \
        -L "${NIGHTLIGHT_LON}" \
        -t "${NIGHTLIGHT_TEMP_NIGHT}" \
        -T "${NIGHTLIGHT_TEMP_DAY}" >/dev/null 2>&1 &
    echo "auto" > "$STATE_FILE"
    notify_waybar
}

start_forced() {
    pkill -x wlsunset 2>/dev/null || true
    sleep 0.1
    # Setting high temp to night temp + 1 forces warm filter 24/7 (wlsunset requires T > t)
    local forced_day=$(( NIGHTLIGHT_TEMP_NIGHT + 1 ))
    nohup wlsunset \
        -t "${NIGHTLIGHT_TEMP_NIGHT}" \
        -T "${forced_day}" >/dev/null 2>&1 &
    echo "on" > "$STATE_FILE"
    notify_waybar
}

stop_nightlight() {
    pkill -x wlsunset 2>/dev/null || true
    echo "off" > "$STATE_FILE"
    notify_waybar
}

cmd="${1:-status}"

case "$cmd" in
    auto)
        start_auto
        ;;
    on|force)
        start_forced
        ;;
    off)
        stop_nightlight
        ;;
    toggle)
        current="$(get_state)"
        case "$current" in
            auto)
                start_forced
                ;;
            on)
                stop_nightlight
                ;;
            off|*)
                start_auto
                ;;
        esac
        ;;
    status|*)
        current="$(get_state)"
        case "$current" in
            on)
                printf '{"text": "󰖔", "tooltip": "Night filter: Forced ON (warm)\\nRight-click to turn OFF", "class": "active"}\n'
                ;;
            auto)
                printf '{"text": "󰖔ᴬ", "tooltip": "Night filter: Auto Schedule\\nRight-click to force ON", "class": "auto"}\n'
                ;;
            off|*)
                printf '{"text": "󰛨", "tooltip": "Night filter: OFF\\nRight-click for Auto Schedule", "class": "inactive"}\n'
                ;;
        esac
        ;;
esac
