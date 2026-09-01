#!/usr/bin/env bash
# Clamshell mode & workspace migration handler for laptop lid events in Hyprland.
# When lid closes with external monitor(s) attached:
#   - Moves all workspaces on eDP-1 to the active external monitor.
#   - Saves the list of moved workspaces.
#   - Disables eDP-1.
# When lid opens:
#   - Re-enables eDP-1 with configured mode, position, and scale.
#   - Restores saved workspaces back to eDP-1.

set -euo pipefail

SAVED_WS_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-lid-saved-workspaces"
LAPTOP_OUTPUT="eDP-1"

LAPTOP_MODE="preferred"
LAPTOP_POS="1920x120"
LAPTOP_SCALE="1.25"

get_external_monitors() {
    hyprctl -j monitors | jq -r --arg lap "$LAPTOP_OUTPUT" '.[] | select(.name != $lap) | .name'
}

get_laptop_workspaces() {
    hyprctl -j workspaces | jq -r --arg lap "$LAPTOP_OUTPUT" '.[] | select(.monitor == $lap) | .id'
}

handle_close() {
    local ext_monitors
    ext_monitors=$(get_external_monitors)

    # If no external monitor is active, do not disable internal screen
    if [[ -z "$ext_monitors" ]]; then
        exit 0
    fi

    # Pick the primary/first external monitor as target
    local target_mon
    target_mon=$(head -n 1 <<< "$ext_monitors")

    # Record the currently active workspace on the target monitor to keep it active (in foreground)
    local target_active_ws
    target_active_ws=$(hyprctl -j monitors | jq -r --arg mon "$target_mon" '.[] | select(.name == $mon) | .activeWorkspace.id // empty')

    # Get workspaces currently on laptop screen
    local ws_list
    ws_list=$(get_laptop_workspaces)

    if [[ -n "$ws_list" ]]; then
        # Save workspaces for restoration upon lid opening
        echo "$ws_list" > "$SAVED_WS_FILE"

        while read -r ws; do
            [[ -n "$ws" ]] || continue
            hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ workspace = ${ws}, monitor = '${target_mon}' }))" >/dev/null 2>&1 || true
        done <<< "$ws_list"
    fi

    # Disable laptop monitor
    hyprctl eval "hl.monitor({ output = '${LAPTOP_OUTPUT}', disabled = true })" >/dev/null 2>&1 || true

    # Refocus the original active workspace on the external monitor so moved workspaces stay in background
    if [[ -n "$target_active_ws" ]]; then
        hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = ${target_active_ws} }))" >/dev/null 2>&1 || true
    fi
}

handle_open() {
    # Re-enable laptop monitor with defined geometry
    hyprctl eval "hl.monitor({ output = '${LAPTOP_OUTPUT}', disabled = false, mode = '${LAPTOP_MODE}', position = '${LAPTOP_POS}', scale = ${LAPTOP_SCALE} })" >/dev/null 2>&1 || true

    sleep 0.2

    # If we have saved workspaces to restore
    if [[ -f "$SAVED_WS_FILE" ]]; then
        local saved_ws
        saved_ws=$(cat "$SAVED_WS_FILE" 2>/dev/null || true)
        rm -f "$SAVED_WS_FILE"

        if [[ -n "$saved_ws" ]]; then
            while read -r ws; do
                [[ -n "$ws" ]] || continue
                hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ workspace = ${ws}, monitor = '${LAPTOP_OUTPUT}' }))" >/dev/null 2>&1 || true
            done <<< "$saved_ws"
        fi
    fi
}

handle_init() {
    local lid_state=""
    if [[ -f /proc/acpi/button/lid/LID0/state ]]; then
        lid_state=$(awk '{print $2}' /proc/acpi/button/lid/LID0/state 2>/dev/null || echo "open")
    elif compgen -G "/proc/acpi/button/lid/*/state" > /dev/null; then
        lid_state=$(awk '{print $2}' /proc/acpi/button/lid/*/state 2>/dev/null | head -n 1 || echo "open")
    fi

    if [[ "$lid_state" == "closed" ]]; then
        handle_close
    else
        handle_open
    fi
}

case "${1:-init}" in
    close)
        handle_close
        ;;
    open)
        handle_open
        ;;
    init|check)
        handle_init
        ;;
    *)
        echo "Usage: $0 {close|open|init|check}" >&2
        exit 1
        ;;
esac
