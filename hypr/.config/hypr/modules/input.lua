hl.config({
	input = {
		kb_layout = "br",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- External Keyboard (All Connection Methods)
local ext_kb = { kb_layout = "us", kb_variant = "intl" }

-- Dongle
hl.device({ name = "compx-2.4g-wireless-receiver",          kb_layout = ext_kb.kb_layout, kb_variant = ext_kb.kb_variant })
hl.device({ name = "compx-2.4g-wireless-receiver-keyboard", kb_layout = ext_kb.kb_layout, kb_variant = ext_kb.kb_variant })

-- Bluetooth
hl.device({ name = "bt-5.0-keyboard-keyboard", kb_layout = ext_kb.kb_layout, kb_variant = ext_kb.kb_variant })

-- USB Cable
hl.device({ name = "by-tech-gaming-keyboard",                  kb_layout = ext_kb.kb_layout, kb_variant = ext_kb.kb_variant })
hl.device({ name = "by-tech-gaming-keyboard-1",                kb_layout = ext_kb.kb_layout, kb_variant = ext_kb.kb_variant })
hl.device({ name = "by-tech-gaming-keyboard-consumer-control", kb_layout = ext_kb.kb_layout, kb_variant = ext_kb.kb_variant })
hl.device({ name = "by-tech-gaming-keyboard-system-control",   kb_layout = ext_kb.kb_layout, kb_variant = ext_kb.kb_variant })

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})
