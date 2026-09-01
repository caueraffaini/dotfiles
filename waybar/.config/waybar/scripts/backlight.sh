#!/usr/bin/env bash
BL="/sys/class/backlight/amdgpu_bl1"
[[ ! -d "$BL" ]] && BL="$(find /sys/class/backlight -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)"
BL_NAME="$(basename "$BL" 2>/dev/null)"
case "$1" in
    up)
        CURRENT=$(cat "$BL/brightness")
        MAX=$(cat "$BL/max_brightness")
        NEW=$(( CURRENT + MAX / 20 ))
        [[ $NEW -gt $MAX ]] && NEW=$MAX
        dbus-send --system --print-reply \
          --dest=org.freedesktop.login1 \
          /org/freedesktop/login1/session/auto \
          org.freedesktop.login1.Session.SetBrightness \
          string:backlight string:"$BL_NAME" uint32:"$NEW" > /dev/null 2>&1
        pkill -RTMIN+9 waybar
        ;;
    down)
        CURRENT=$(cat "$BL/brightness")
        MAX=$(cat "$BL/max_brightness")
        NEW=$(( CURRENT - MAX / 20 ))
        [[ $NEW -lt 0 ]] && NEW=0
        dbus-send --system --print-reply \
          --dest=org.freedesktop.login1 \
          /org/freedesktop/login1/session/auto \
          org.freedesktop.login1.Session.SetBrightness \
          string:backlight string:"$BL_NAME" uint32:"$NEW" > /dev/null 2>&1
        pkill -RTMIN+9 waybar
        ;;
    *)
        CURRENT=$(cat "$BL/brightness")
        MAX=$(cat "$BL/max_brightness")
        pct=$(( CURRENT * 100 / MAX ))
        ICONS=("󰃞" "󰃟" "󰃠" "󰃠" "󰃠")
        idx=$(( pct * 4 / 100 ))
        [[ $idx -gt 4 ]] && idx=4
        icon="${ICONS[$idx]}"
        nightlight=""
        cls=""
        STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/nightlight.state"
        state="off"
        if pgrep -x wlsunset > /dev/null 2>&1; then
            if [[ -f "$STATE_FILE" ]]; then
                state=$(cat "$STATE_FILE")
            else
                state="auto"
            fi
        fi

        case "$state" in
            on)
                cls="nightlight-active"
                nightlight="Night filter: Forced ON (right-click to turn OFF)"
                icon="󰖔"
                ;;
            auto)
                cls="nightlight-auto"
                nightlight="Night filter: Auto Schedule (right-click to force ON)"
                icon="󰖔ᴬ"
                ;;
            off|*)
                cls=""
                nightlight="Night filter: OFF (right-click for Auto Schedule)"
                ;;
        esac

        tooltip="Brightness: ${pct}%\n${nightlight}"
        printf '{"text": "%s %d%%", "tooltip": "%s", "class": "%s"}\n' "$icon" "$pct" "$tooltip" "$cls"
        ;;
esac
