#!/usr/bin/env bash
GPU_DIR=$(for d in /sys/class/drm/card*/device; do [ -f "$d/gpu_busy_percent" ] && echo "$d" && break; done)
HW_DIR=$(ls -d "$GPU_DIR"/hwmon/hwmon* 2>/dev/null | head -1)

usage=$(cat "$GPU_DIR/gpu_busy_percent" 2>/dev/null || echo 0)
temp=$(( $(cat "$HW_DIR/temp1_input" 2>/dev/null || echo 0) / 1000 ))
freq_mhz=$(( $(cat "$HW_DIR/freq1_input" 2>/dev/null || echo 0) / 1000000 ))
vram_used=$(( $(cat "$GPU_DIR/mem_info_vram_used" 2>/dev/null || echo 0) / 1048576 ))
vram_total=$(( $(cat "$GPU_DIR/mem_info_vram_total" 2>/dev/null || echo 0) / 1048576 ))
vram_pct=$(( vram_used * 100 / (vram_total > 0 ? vram_total : 1) ))

tooltip="GPU: ${usage}% @ ${freq_mhz} MHz\nTemp: ${temp}°C\nVRAM: ${vram_used} MB / ${vram_total} MB (${vram_pct}%)"
printf '{"text": " %d%%   %d%%   %d°", "tooltip": "%s"}\n' \
    "$usage" "$vram_pct" "$temp" "$tooltip"
