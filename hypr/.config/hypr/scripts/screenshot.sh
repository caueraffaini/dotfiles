#!/usr/bin/env bash

# Arch Screenshot script (grim + slurp + swappy)
# Logic: click -> window, drag -> region

DIR="$HOME/Pictures/Screenshots"
NAME="screenshot_$(date +%Y%m%d_%H%M%S).png"
FILE="$DIR/$NAME"

mkdir -p "$DIR"

# Get window geometries for slurp
# hyprctl -j clients -> jq -> slurp format
get_windows() {
    hyprctl -j clients | jq -r '.[] | select(.workspace.id != -1) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

case $1 in
    fullscreen)
        # Get active monitor geometry
        GEOM=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | "\(.x),\(.y) \(.width)x\(.height)"')
        grim -g "$GEOM" "$FILE"
        wl-copy < "$FILE"
        notify-send "Screenshot" "Active monitor captured" -i "$FILE"
        ;;
    region)
        # slurp -d: drag or click
        # we provide window geometries to slurp so click selects window
        GEOM=$(get_windows | slurp)
        if [ -n "$GEOM" ]; then
            grim -g "$GEOM" "$FILE"
            wl-copy < "$FILE"
            notify-send "Screenshot" "Region captured" -i "$FILE"
        fi
        ;;
    annotate)
        GEOM=$(get_windows | slurp)
        if [ -n "$GEOM" ]; then
            # Capture to swappy for annotation
            grim -g "$GEOM" - | swappy -f - -o "$FILE"
            if [ -f "$FILE" ]; then
                wl-copy < "$FILE"
                notify-send "Screenshot" "Annotated and saved" -i "$FILE"
            fi
        fi
        ;;
    *)
        echo "Usage: $0 {fullscreen|region|annotate}"
        exit 1
        ;;
esac
