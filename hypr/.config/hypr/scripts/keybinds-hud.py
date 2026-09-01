#!/usr/bin/env python3
"""
Hyprland Keybindings Cheatsheet HUD
Centered floating modal window displaying organized keybindings with styled keycaps.
Gruvbox Material Dark design system tokens.
"""

import os
import sys
import signal
import html
import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, Gdk, GLib

PID_FILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or f"/tmp/runtime-{os.getuid()}", "hypr-keybinds-hud.pid")
os.makedirs(os.path.dirname(PID_FILE), mode=0o700, exist_ok=True)

# Single-instance toggle: if already running, kill existing and exit
if os.path.exists(PID_FILE):
    try:
        with open(PID_FILE, "r") as f:
            old_pid = int(f.read().strip())
        if old_pid != os.getpid():
            os.kill(old_pid, signal.SIGTERM)
            os.remove(PID_FILE)
            sys.exit(0)
    except (ValueError, ProcessLookupError, PermissionError):
        pass

with open(PID_FILE, "w") as f:
    f.write(str(os.getpid()))

def cleanup_pid():
    if os.path.exists(PID_FILE):
        try:
            os.remove(PID_FILE)
        except OSError:
            pass


# Keybinding groups & definitions
COLUMNS = [
    # Column 1
    [
        {
            "title": "System & Session",
            "icon": "󰍹",
            "accent": "#fabd2f",  # br_yellow
            "items": [
                (["SUPER", "Space"], "Application Launcher (Rofi)"),
                (["SUPER", "K"], "Keybindings Cheatsheet"),
                (["SUPER", "L"], "Lock Session (Hyprlock)"),
                (["SUPER", "M"], "Power Menu (Powermenu)"),
                (["SUPER", "SHIFT", "M"], "System Actions (Sysmenu)"),
                (["SUPER", "N"], "Notification Center (SwayNC)"),
            ],
        },
        {
            "title": "Workspaces & Displays",
            "icon": "󰖲",
            "accent": "#fe8019",  # br_orange
            "items": [
                (["SUPER", "0–9"], "Switch to Workspace 1–10"),
                (["SUPER", "SHIFT", "0–9"], "Move Window to Workspace"),
                (["SUPER", "S"], "Toggle Special Workspace (Magic)"),
                (["SUPER", "SHIFT", "S"], "Move Window to Special:Magic"),
                (["SUPER", "Scroll"], "Cycle Workspaces (Up / Down)"),
                (["Lid Switch"], "Clamshell Mode Migration"),
            ],
        },
    ],
    # Column 2
    [
        {
            "title": "Windows & Tiling",
            "icon": "🪟",
            "accent": "#8ec07c",  # br_aqua
            "items": [
                (["SUPER", "Return"], "Terminal (Ghostty)"),
                (["SUPER", "W"], "Close Focused Window"),
                (["SUPER", "F"], "Toggle Window Floating"),
                (["SUPER", "P"], "Toggle Pseudo-Tile Mode"),
                (["SUPER", "J"], "Toggle Dwindle Split Direction"),
                (["SUPER", "← / → / ↑ / ↓"], "Focus Window Direction"),
                (["SUPER", "Mouse L/R"], "Drag Move / Resize Window"),
            ],
        },
        {
            "title": "Applications & Utilities",
            "icon": "🚀",
            "accent": "#83a598",  # br_blue
            "items": [
                (["SUPER", "C / V"], "Universal Copy / Paste"),
                (["SUPER", "G"], "AGY AI Coding Assistant"),
                (["SUPER", "SHIFT", "E"], "Neovim Text Editor"),
                (["SUPER", "B"], "Firefox Web Browser"),
                (["SUPER", "E"], "Yazi File Manager"),
                (["SUPER", "O"], "Spotify (Desktop App)"),
                (["SUPER", "A"], "Audio Mixer (Pulsemixer)"),
                (["SUPER", "I"], "Wi-Fi Settings (Impala)"),
                (["SUPER", "SHIFT", "B"], "Bluetooth Manager (Bluetui)"),
                (["SUPER", "SHIFT", "V"], "Clipboard Picker (Cliphist)"),
                (["SUPER", "SHIFT", "C"], "Color Picker (Hyprpicker)"),
                (["Print / SHIFT / SUPER"], "Screenshots (Full / Region / Annotate)"),
            ],
        },
    ],
]

CSS = """
window {
    background-color: #282828;
    border: 1px solid #504945;
    border-radius: 10px;
}

.main-container {
    background-color: #282828;
    padding: 20px;
}

.header-box {
    margin-bottom: 14px;
    padding-bottom: 10px;
    border-bottom: 1px solid #3c3836;
}

.title-text {
    font-family: 'Atkinson Hyperlegible', sans-serif;
    font-size: 18px;
    font-weight: bold;
    color: #fabd2f;
}

.hint-text {
    font-family: 'Atkinson Hyperlegible', sans-serif;
    font-size: 12px;
    color: #928374;
}

.close-btn {
    background-color: #3c3836;
    border: 1px solid #504945;
    border-radius: 4px;
    color: #ebdbb2;
    padding: 4px 12px;
    font-family: 'Atkinson Hyperlegible', sans-serif;
    font-size: 12px;
    font-weight: bold;
}

.close-btn:hover {
    background-color: #fb4934;
    border-color: #fb4934;
    color: #282828;
}

.section-box {
    background-color: #32302f;
    border: 1px solid #3c3836;
    border-radius: 6px;
    padding: 10px 12px;
    margin-bottom: 10px;
}

.section-header {
    margin-bottom: 6px;
}

.section-title {
    font-family: 'Atkinson Hyperlegible', sans-serif;
    font-size: 13px;
    font-weight: bold;
}

.bind-row {
    padding: 2px 0;
}

.keycap {
    background-color: #3c3836;
    border: 1px solid #504945;
    border-bottom: 2px solid #1d2021;
    border-radius: 4px;
    color: #fabd2f;
    font-family: 'JetBrainsMono Nerd Font', monospace;
    font-weight: bold;
    font-size: 10.5px;
    padding: 1.5px 5.5px;
    margin-right: 3px;
}

.keycap-normal {
    color: #ebdbb2;
}

.key-plus {
    color: #7c6f64;
    font-size: 10px;
    margin-right: 3px;
}

.desc-text {
    font-family: 'Atkinson Hyperlegible', sans-serif;
    font-size: 12px;
    color: #d5c4a1;
}
"""

class KeybindsHudApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="com.caue.keybindshud")

    def do_activate(self):
        win = Gtk.ApplicationWindow(application=self)
        win.set_title("Hyprland Keybindings Cheatsheet")
        win.set_default_size(880, 600)
        win.set_resizable(False)

        # Apply CSS
        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(CSS.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        main_box.add_css_class("main-container")

        # Header Box
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        header.add_css_class("header-box")

        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        title_lbl = Gtk.Label(label="󰌌  Hyprland Keybindings", xalign=0)
        title_lbl.add_css_class("title-text")
        hint_lbl = Gtk.Label(label="Press ESC or Super+K to close", xalign=0)
        hint_lbl.add_css_class("hint-text")
        title_box.append(title_lbl)
        title_box.append(hint_lbl)
        header.append(title_box)

        # Spacer
        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        header.append(spacer)

        # Close button
        close_btn = Gtk.Button(label="✕ Close")
        close_btn.add_css_class("close-btn")
        close_btn.connect("clicked", lambda b: self.exit_app())
        header.append(close_btn)

        main_box.append(header)

        # 2-Column Content Grid
        columns_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        columns_box.set_homogeneous(True)

        for col_data in COLUMNS:
            col_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

            for section in col_data:
                sec_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
                sec_box.add_css_class("section-box")

                # Section Header
                sec_hdr = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
                sec_hdr.add_css_class("section-header")

                sec_title = Gtk.Label(xalign=0)
                sec_title.add_css_class("section-title")
                safe_title = html.escape(section["title"])
                safe_icon = html.escape(section["icon"])
                sec_title.set_markup(f"<span foreground='{section['accent']}'>{safe_icon}  {safe_title}</span>")

                sec_hdr.append(sec_title)
                sec_box.append(sec_hdr)

                # Items
                for keys, desc in section["items"]:
                    row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
                    row.add_css_class("bind-row")

                    # Keycaps Box
                    keys_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
                    for i, k in enumerate(keys):
                        key_lbl = Gtk.Label(label=k)
                        key_lbl.add_css_class("keycap")
                        if k not in ("SUPER", "SHIFT", "CTRL", "ALT"):
                            key_lbl.add_css_class("keycap-normal")
                        keys_box.append(key_lbl)
                        if i < len(keys) - 1 and keys[i+1] not in ("Mouse L/R", "Scroll", "0–9"):
                            plus = Gtk.Label(label="+")
                            plus.add_css_class("key-plus")
                            keys_box.append(plus)

                    row.append(keys_box)

                    # Dot Leader / Separator
                    row_spacer = Gtk.Box()
                    row_spacer.set_hexpand(True)
                    row.append(row_spacer)

                    # Description Label
                    desc_lbl = Gtk.Label(label=desc, xalign=1)
                    desc_lbl.add_css_class("desc-text")
                    row.append(desc_lbl)

                    sec_box.append(row)

                col_box.append(sec_box)

            columns_box.append(col_box)

        main_box.append(columns_box)
        win.set_child(main_box)

        # Keyboard listener (Escape / Q to exit)
        key_ctrl = Gtk.EventControllerKey.new()
        def on_key(ctrl, keyval, keycode, state):
            if keyval in (Gdk.KEY_Escape, Gdk.KEY_q, Gdk.KEY_Q):
                self.exit_app()
                return True
            return False
        key_ctrl.connect("key-pressed", on_key)
        win.add_controller(key_ctrl)

        win.present()

    def exit_app(self):
        cleanup_pid()
        self.quit()

if __name__ == "__main__":
    signal.signal(signal.SIGINT, lambda s, f: cleanup_pid() or sys.exit(0))
    signal.signal(signal.SIGTERM, lambda s, f: cleanup_pid() or sys.exit(0))
    app = KeybindsHudApp()
    app.run(sys.argv)
