#!/bin/bash
# Sets wallpaper via awww (AUR pkg awww-daemon, not swww).
# Looks for ~/Pictures/wallpapers/current (symlink or file) first,
# then picks a random image from ~/Pictures/wallpapers/.
# No wallpaper found → exits silently (leaves daemon running, blank).

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CURRENT="$WALLPAPER_DIR/current"

SWWW_OPTS=(
    --transition-type     grow
    --transition-pos      "0.5,0.5"
    --transition-duration 1.5
    --transition-fps      60
    --transition-bezier   "0.23,1,0.32,1"
)


if [[ -f "$CURRENT" ]]; then
    TARGET="$CURRENT"
else
    TARGET=$(find "$WALLPAPER_DIR" -maxdepth 1 \
        \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \
           -o -name "*.gif" -o -name "*.webp" \) \
        2>/dev/null | shuf -n1)
fi

[[ -n "$TARGET" ]] && awww img "$TARGET" "${SWWW_OPTS[@]}"
