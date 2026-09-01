#!/usr/bin/env bash
# Power state monitor for Hyprland.
# Owns hypridle lifecycle: starts the correct config on battery, kills it on AC.
# Monitors low battery and dims backlight at 20% (→30%) and 10% (→0%).

BL_DEV="/sys/class/backlight/amdgpu_bl1"
BRIGHT_SAVE="${XDG_RUNTIME_DIR:-/tmp/runtime-${UID:-$(id -u)}}/power-sync.savedbright"
mkdir -p "$(dirname "$BRIGHT_SAVE")"
HYPRIDLE_CONF_DIR="$HOME/.config/hypr"


LAST_AC=""
LAST_PROFILE=""
LOW_NOTIFIED=0
CRIT_NOTIFIED=0

set_backlight() {
    local pct="$1"
    local max
    max=$(< "$BL_DEV/max_brightness")
    local val=$(( max * pct / 100 ))
    dbus-send --system --print-reply \
        --dest=org.freedesktop.login1 \
        /org/freedesktop/login1/session/auto \
        org.freedesktop.login1.Session.SetBrightness \
        string:backlight string:amdgpu_bl1 uint32:"$val" > /dev/null 2>&1 \
        || systemd-cat -t power-sync -p err <<< "SetBrightness failed (pct=$pct val=$val)"
    pkill -RTMIN+9 waybar 2>/dev/null
}

save_backlight() {
    local max cur
    max=$(< "$BL_DEV/max_brightness")
    cur=$(< "$BL_DEV/brightness")
    echo $(( cur * 100 / max )) > "$BRIGHT_SAVE"
}

restore_backlight() {
    [[ -f "$BRIGHT_SAVE" ]] || return
    local saved
    saved=$(< "$BRIGHT_SAVE")
    rm -f "$BRIGHT_SAVE"
    set_backlight "$saved"
}

start_hypridle() {
    local profile="$1"
    local conf="$HYPRIDLE_CONF_DIR/hypridle-${profile}.conf"
    [[ -f "$conf" ]] || return
    killall hypridle 2>/dev/null
    sleep 0.2
    # Swap the active config symlink; run plain hypridle (v0.1.7 -c flag
    # does not bypass default config search, crashes if hypridle.conf missing)
    ln -sf "$conf" "$HYPRIDLE_CONF_DIR/hypridle.conf"
    hypridle &
}

stop_hypridle() {
    killall hypridle 2>/dev/null
}

desired_hypridle_conf() {
    local ac="$1" profile="$2"
    [[ "$ac" == "1" ]] && echo "" && return
    case "$profile" in
        performance) echo "performance" ;;
        balanced)    echo "balanced" ;;
        *)           echo "powersaver" ;;
    esac
}

while true; do
    AC=$(cat /sys/class/power_supply/*/online 2>/dev/null | head -n 1 || echo "1")
    PROFILE=$(powerprofilesctl get 2>/dev/null || echo "balanced")
    CAP=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1 || echo "100")

    # AC/battery transitions
    if [[ "$AC" != "$LAST_AC" ]]; then
        if [[ "$AC" == "1" ]]; then
            powerprofilesctl set performance
            notify-send -h string:x-canonical-private-synchronous:power-sync "Power" "AC connected — Performance mode" -i battery-full-charging
            restore_backlight
            LOW_NOTIFIED=0
            CRIT_NOTIFIED=0
            stop_hypridle
        else
            powerprofilesctl set balanced
            notify-send -h string:x-canonical-private-synchronous:power-sync "Power" "On battery — Balanced mode" -i battery
        fi
        LAST_AC="$AC"
        PROFILE=$(powerprofilesctl get 2>/dev/null || echo "balanced")
    fi

    # Hypridle config swap (battery only; also catches manual profile changes)
    if [[ "$AC" != "1" ]]; then
        DESIRED=$(desired_hypridle_conf "$AC" "$PROFILE")
        if [[ "$DESIRED" != "$LAST_PROFILE" ]]; then
            start_hypridle "$DESIRED"
            LAST_PROFILE="$DESIRED"
        fi
    else
        LAST_PROFILE=""
    fi

    # Low battery handling (battery only)
    if [[ "$AC" != "1" ]]; then
        if (( CAP < 10 )) && (( CRIT_NOTIFIED == 0 )); then
            [[ $LOW_NOTIFIED -eq 0 ]] && save_backlight
            notify-send -u critical -h string:x-canonical-private-synchronous:power-sync "Battery" "Critical — below 10%. Dimming screen." -i battery-empty
            set_backlight 0
            LOW_NOTIFIED=1
            CRIT_NOTIFIED=1
        elif (( CAP <= 20 )) && (( CAP >= 10 )) && (( LOW_NOTIFIED == 0 )); then
            save_backlight
            notify-send -u normal -h string:x-canonical-private-synchronous:power-sync "Battery" "Low — 20% remaining. Dimming screen." -i battery-low
            set_backlight 30
            LOW_NOTIFIED=1
        elif (( CAP > 20 )); then
            LOW_NOTIFIED=0
            CRIT_NOTIFIED=0
        fi
    fi

    sleep 10
done
