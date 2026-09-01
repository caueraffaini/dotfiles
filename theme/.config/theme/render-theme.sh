#!/usr/bin/env bash
# Central theme renderer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/render-theme.py"

if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    echo "Error: render-theme.py not found in $SCRIPT_DIR"
    exit 1
fi

python3 "$PYTHON_SCRIPT" "$@"
