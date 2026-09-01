#!/usr/bin/env bash
# config-guard — watch dotfiles for waybar/hypr changes; parse-check + notify on error.
# Runs as systemd user service; depends on inotifywait (inotify-tools).
set -euo pipefail

DOTFILES="${HOME}/dotfiles"
CFG_WAYBAR="${HOME}/.config/waybar/config.jsonc"

notify_err()  { notify-send -u critical "config-guard" "$*"; }
notify_info() { notify-send -u normal  "config-guard" "$*"; }

check_waybar_json() {
    python3 - "$CFG_WAYBAR" <<'PYEOF' 2>&1
import sys, json, re
txt = open(sys.argv[1]).read()
txt = re.sub(r'//[^\n]*', '', txt)
txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
txt = re.sub(r',\s*([}\]])', r'\1', txt)
try:
    json.loads(txt)
except json.JSONDecodeError as e:
    print(e)
    sys.exit(1)
PYEOF
}

inotifywait -q -r -m -e close_write \
    "${DOTFILES}/waybar/.config/waybar/" \
    "${DOTFILES}/hypr/.config/hypr/" \
    --format '%w%f' 2>/dev/null |
while IFS= read -r file; do
    fname="${file##*/}"
    case "$file" in
        *.jsonc)
            if errmsg=$(check_waybar_json 2>&1); then
                notify_info "waybar config OK: ${fname} — run: sys-reload waybar"
            else
                notify_err  "waybar INVALID: ${fname}: ${errmsg}"
            fi
            ;;

        *.css.template|style.css*)
            notify_info "waybar style changed: ${fname} — run: sys-reload waybar"
            ;;
        *.lua)
            notify_info "hypr config changed: ${fname} — run: sys-reload hypr"
            ;;
        *.template)
            notify_info "template changed: ${fname} — run: render-theme.sh"
            ;;
    esac
done
