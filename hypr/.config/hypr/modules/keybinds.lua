local terminal    = "ghostty"
local fileManager = "ghostty -e yazi"
local editor      = "ghostty -e nvim"
local menu        = "rofi -show drun"
local mainMod     = "SUPER"

local is_terminal = function(class)
	if not class then return false end
	class = string.lower(class)
	return class:find("ghostty") ~= nil
		or class:find("kitty") ~= nil
		or class:find("alacritty") ~= nil
		or class:find("foot") ~= nil
		or class:find("wezterm") ~= nil
		or class:find("xterm") ~= nil
end

local copy_action = function()
	local win = hl.get_active_window()
	if win and is_terminal(win.class) then
		hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "c" }))
	else
		hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "c" }))
	end
end

local paste_action = function()
	local win = hl.get_active_window()
	if win and is_terminal(win.class) then
		hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "v" }))
	else
		hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "v" }))
	end
end

-- Universal Copy & Paste
hl.bind(mainMod .. " + C", copy_action)
hl.bind(mainMod .. " + V", paste_action)

-- System & Session
hl.bind(mainMod .. " + Space",     hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds-hud.py"))
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("~/.config/hypr/scripts/powermenu.sh"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("~/.local/bin/sysmenu"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind("XF86PowerOff",            hl.dsp.exec_cmd("~/.config/hypr/scripts/powermenu.sh"))

-- Window Management & Tiling
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W",      hl.dsp.window.close())
hl.bind(mainMod .. " + F",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key,          hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key,  hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Laptop Lid Switch (Clamshell mode)
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("~/.config/hypr/scripts/lid-handler.sh close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/scripts/lid-handler.sh open"),  { locked = true })

-- Applications & TUI Tools
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd("flatpak run org.mozilla.firefox"))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + G",         hl.dsp.exec_cmd("ghostty -e agy"))
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd("ghostty --class=com.tui.float --confirm-close-surface=false -e pulsemixer"))
hl.bind(mainMod .. " + I",         hl.dsp.exec_cmd("ghostty --class=com.tui.float --confirm-close-surface=false -e impala"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("ghostty --class=com.tui.float --confirm-close-surface=false -e bluetui"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/hypr/clipboard.sh"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- Screenshots
hl.bind("Print",                   hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh fullscreen"))
hl.bind("SHIFT + Print",           hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh region"))
hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh annotate"))

-- Media & Hardware Keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+ && pkill -RTMIN+9 waybar"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%- && pkill -RTMIN+9 waybar"),  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),    { locked = true })
