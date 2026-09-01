hl.on("hyprland.start", function()
	-- Propagate Wayland env
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Portal restart
	hl.exec_cmd("sleep 0.5 && systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk")
	hl.exec_cmd("sleep 1 && systemctl --user start xdg-desktop-portal")

	-- Secret Service provider (keytar/libsecret credential storage)
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

	-- Daemons (hypridle lifecycle owned by power-sync.sh)
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("sleep 0.5 && ~/.config/hypr/wallpaper.sh")
	hl.exec_cmd("~/.config/waybar/scripts/link-k10temp.sh")
	hl.exec_cmd("sleep 1 && waybar")
	hl.exec_cmd("swaync")
	hl.exec_cmd("rfkill unblock bluetooth")
	hl.exec_cmd("bluetoothctl power on")

	-- Clipboard
	hl.exec_cmd("wl-paste --type text  --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Power state sync background script
	hl.exec_cmd("killall power-sync.sh; ~/.config/hypr/scripts/power-sync.sh")

	-- Night filter: auto schedule via nightlight.sh (reads ~/.config/nightlight.conf)
	hl.exec_cmd("~/.config/waybar/scripts/nightlight.sh auto")

	-- Initial laptop lid state check (clamshell mode)
	hl.exec_cmd("sleep 1 && ~/.config/hypr/scripts/lid-handler.sh init")
end)
