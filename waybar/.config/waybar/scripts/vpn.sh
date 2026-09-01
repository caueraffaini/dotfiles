#!/usr/bin/env bash
# Waybar ProtonVPN (WireGuard) state + toggle.
# No-arg: emit JSON state. "toggle": bring proton-us up/down (scoped NOPASSWD sudo).
IFACE="proton-us"
ICON_ON="󰦝"   # nf-md-shield_lock — connected
ICON_OFF="󰦞"  # nf-md-shield_off  — disconnected

is_up() { /usr/bin/ip -br link show "$IFACE" &>/dev/null; }

if [[ "$1" == "toggle" ]]; then
    if is_up; then
        /usr/bin/sudo /usr/bin/wg-quick down "$IFACE"
    else
        /usr/bin/sudo /usr/bin/wg-quick up "$IFACE"
    fi
    /usr/bin/pkill -RTMIN+12 waybar
    exit 0
fi

if is_up; then
    printf '{"text": "%s", "tooltip": "ProtonVPN (US) — connected", "class": "connected"}\n' "$ICON_ON"
else

    printf '{"text": "%s", "tooltip": "VPN off — click to connect", "class": "disconnected"}\n' "$ICON_OFF"
fi
