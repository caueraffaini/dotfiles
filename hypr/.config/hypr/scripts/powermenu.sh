#!/usr/bin/env bash

# Power menu using Rofi

options="⏻ Shutdown\n󰜉 Reboot\n󰒲 Hibernate\n Lock"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "  power" -theme-str 'listview {lines: 4;} window {width: 250px;}')

case "$chosen" in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "󰜉 Reboot")
        systemctl reboot
        ;;
    "󰒲 Hibernate")
        systemctl hibernate
        ;;
    " Lock")
        loginctl lock-session
        ;;
esac
