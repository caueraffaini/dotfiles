hl.env("XCURSOR_THEME",  "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE",   "24")
hl.env("HYPRCURSOR_SIZE","24")

hl.env("GTK_THEME",      "Gruvbox-Material-Dark")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_STYLE_OVERRIDE",    "kvantum")

-- Xwayland on the 1.25-scaled eDP-1: without force_zero_scaling, X11
-- apps (Steam) render at 1x then get bilinear-upscaled = blurry/low-res.
-- force_zero_scaling makes Xwayland render at native pixels (crisp);
-- Steam then needs its own UI scaling factor to be the right size.
hl.config({ xwayland = { force_zero_scaling = true } })
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "1.25")
