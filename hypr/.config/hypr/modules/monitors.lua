-- Monitor configuration (Lua)
-- Laptop (eDP-1): 1920x1200 scaled to 1.25 (logical 1536x960)
-- TV (HDMI-A-1): 1920x1080 scaled to 1.0 (logical 1920x1080)
-- Setup: TV on the LEFT, Laptop on the RIGHT. Bottoms aligned.
-- Laptop_Y = Logical_TVHeight - Logical_LaptopHeight = 1080 - 960 = 120.

-- TV (HDMI-A-1) on the LEFT
hl.monitor({
	output = "HDMI-A-1",
	mode = "preferred",
	position = "0x0",
	scale = 1,
})

-- Laptop (eDP-1) on the RIGHT
hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "1920x120",
	scale = 1.25,
})

-- Generic fallback for any other display (HDMI/USB-C)
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})
