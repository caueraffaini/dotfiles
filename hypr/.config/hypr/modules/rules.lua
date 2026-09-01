hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "tui-float",
	match = { class = "com.tui.float" },
	float = true,
	size = "60% 60%",
	center = true,
})

hl.window_rule({
	name = "tui-btop",
	match = { class = "com.tui.btop" },
	float = true,
	size = "80% 65%",
	center = true,
})

hl.window_rule({
	name = "keybinds-hud",
	match = { class = "com.caue.keybindshud" },
	float = true,
	size = "880 600",
	center = true,
	stay_focused = true,
})
