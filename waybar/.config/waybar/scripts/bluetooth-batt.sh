#!/usr/bin/env bash
declare -A ICON_MAP=(
    ["audio-headset"]=""
    ["audio-headphones"]=""
    ["input-keyboard"]=""
    ["input-mouse"]=""
    ["phone"]=""
    ["audio-card"]=""
)

status=$(bluetoothctl show 2>/dev/null | grep "Powered" | awk '{print $2}')
if [[ "$status" != "yes" ]]; then
    printf '{"text": "%s off", "tooltip": "Bluetooth off", "class": "off"}\n' ""
    exit 0
fi

connected=$(bluetoothctl devices Connected 2>/dev/null)
if [[ -z "$connected" ]]; then
    printf '{"text": "%s", "tooltip": "No devices connected", "class": "disconnected"}\n' ""
    exit 0
fi

parts=()
tooltip_lines=()
while IFS= read -r line; do
    mac=$(echo "$line" | awk '{print $2}' | tr -d '\r')
    [[ -z "$mac" ]] && continue
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    icon_key=$(echo "$info" | grep "Icon:" | awk '{print $2}' | tr -d '\r')
    
    # Robust battery extraction
    batt_info=$(echo "$info" | grep -i "Battery Percentage:")
    batt=""
    if [[ -n "$batt_info" ]]; then
        # Try decimal in parens (100%)
        batt=$(echo "$batt_info" | grep -oP '\(\K[0-9]+(?=%\))')
        if [[ -z "$batt" ]]; then
            # Try hex 0x64
            batt_hex=$(echo "$batt_info" | grep -oP '0x[0-9a-f]+' | head -n 1)
            [[ -n "$batt_hex" ]] && batt=$(printf '%d' "$batt_hex" 2>/dev/null)
        fi
        if [[ -z "$batt" ]]; then
            # Fallback to last number in line
            batt=$(echo "$batt_info" | grep -oP '[0-9]+' | tail -n 1)
        fi
    fi

    name=$(echo "$info" | grep "Name:" | cut -d' ' -f2- | tr -d '\r' | sed 's/"//g')

    glyph="${ICON_MAP[$icon_key]:-}"
    if [[ -n "$batt" ]]; then
        parts+=("$glyph ${batt}%")
        tooltip_lines+=("${name}: $glyph ${batt}%")
    else
        parts+=("$glyph")
        tooltip_lines+=("${name}: $glyph")
    fi
done <<< "$connected"

if [[ ${#parts[@]} -eq 0 ]]; then
    printf '{"text": "%s", "tooltip": "No devices connected", "class": "disconnected"}\n' ""
    exit 0
fi

text=" $(printf '%s  ' "${parts[@]}" | sed 's/  $//')"
tooltip=$(printf '%s\\n' "${tooltip_lines[@]}" | sed 's/\\n$//')
printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip"
