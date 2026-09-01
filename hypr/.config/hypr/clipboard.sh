#!/bin/bash
# cliphist picker with image thumbnail previews in rofi.
# Thumbnails cached in ~/.cache/cliphist-thumbs/ — generated once per entry.
# Requires: cliphist, rofi, wl-copy, file(1), magick (imagemagick)

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs"
mkdir -p "$CACHE"

build_entries() {
    while IFS= read -r entry; do
        id=$(printf '%s' "$entry" | cut -f1)
        thumb="$CACHE/$id.png"
        skip="$CACHE/$id.skip"

        # Generate thumbnail once; mark non-images so we skip decoding next time
        if [[ ! -f "$thumb" && ! -f "$skip" ]]; then
            tmp=$(mktemp)
            cliphist decode <<< "$entry" > "$tmp" 2>/dev/null
            mime=$(file --brief --mime-type "$tmp")
            if [[ "$mime" == image/* ]]; then
                magick "$tmp" -thumbnail 80x80^ -gravity center -extent 80x80 \
                    "$thumb" 2>/dev/null || touch "$skip"
            else
                touch "$skip"
            fi
            rm -f "$tmp"
        fi

        if [[ -f "$thumb" ]]; then
            printf '%s\0icon\x1f%s\n' "$entry" "$thumb"
        else
            printf '%s\n' "$entry"
        fi
    done < <(cliphist list)
}

selected=$(build_entries | rofi -dmenu -p "  clipboard" -show-icons)
[[ -z "$selected" ]] && exit 0

tmp=$(mktemp)
cliphist decode <<< "$selected" > "$tmp"

mime=$(file --brief --mime-type "$tmp")
case "$mime" in
    image/*) wl-copy --type "$mime" < "$tmp" ;;
    *)       wl-copy < "$tmp" ;;
esac

rm -f "$tmp"
