#!/usr/bin/env bash

# Find hwmon path for k10temp
# /sys/class/hwmon/hwmon*/name contains the driver name
K10TEMP_PATH=$(grep -l "k10temp" /sys/class/hwmon/hwmon*/name | head -n 1 | xargs dirname)

if [ -z "$K10TEMP_PATH" ]; then
    echo "k10temp not found"
    exit 1
fi

# Link to a stable location in /tmp
# Use -s (symbolic) -f (force) -n (no-dereference)
ln -sfn "$K10TEMP_PATH" "/tmp/waybar-k10temp"

