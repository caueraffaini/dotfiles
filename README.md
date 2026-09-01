<div align="center">

# 🌿 Dotfiles — Arch Linux & Hyprland

**Resilient, minimal, and aesthetic Gruvbox Material Dark Wayland environment managed with GNU Stow.**

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-00AAFF?style=for-the-badge&logo=hyprland&logoColor=white)](https://hyprland.org/)
[![Wayland](https://img.shields.io/badge/Wayland-005A9C?style=for-the-badge&logo=wayland&logoColor=white)](https://wayland.freedesktop.org/)
[![Theme](https://img.shields.io/badge/Theme-Gruvbox_Material-D79921?style=for-the-badge)](theme/.config/theme/palette.json)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

</div>

---

## 📸 Highlights & Architecture

* **Compositor:** [Hyprland](https://hyprland.org/) — Modular **Lua configuration** (`hyprland.lua` + `modules/`), multi-monitor display management, and dynamic clamshell lid migration.
* **Aesthetic & Theming:** **Gruvbox Material Dark** — Single source-of-truth palette (`palette.json`) compiled into GUI and TUI configurations via template rendering.
* **Terminal & Shell:** [Ghostty](https://ghostty.org/) + [Zsh](https://www.zsh.org/) + [Starship](https://starship.rs/) + [FZF](https://github.com/junegunn/fzf) + [Eza](https://github.com/eza-community/eza) + [Bat](https://github.com/sharkdp/bat).
* **Bar & Status:** [Waybar](https://github.com/Alexays/Waybar) (floating top bar with ProtonVPN WireGuard toggle, restic backup progress, Btrfs snapshot health, and GPU/CPU telemetry).
* **Notifications & Launcher:** [SwayNC](https://github.com/ErikReider/SwayNotificationCenter) + [Rofi (Wayland)](https://github.com/lbonn/rofi) + custom `sysmenu` actions sheet.
* **Editor & File Manager:** [Neovim](https://neovim.io/) (LazyVim + Gruvbox Material + Lua LSP tuned for Hyprland globals) + [Yazi](https://github.com/sxyazi/yazi) (TUI file manager).
* **Greeter:** [greetd](https://git.sr.ht/~kennylevinsen/greetd) + [tuigreet](https://github.com/apognu/tuigreet).
* **Safety & Reliability:** Snapper Btrfs pre/post snapshot wrapper (`safe-sysmod`), Restic cloud backup monitor, and automated configuration drift detection (`dotfiles-drift`).

---

## 📦 Package Catalog

Every directory represents an isolated GNU Stow package mapping into `$HOME` (or `/` for system targets):

| Package | Stow Target | Description |
|---|---|---|
| `hypr` | `~/.config/hypr/` | Hyprland Lua modules, hyprlock, hypridle power states, helper scripts |
| `waybar` | `~/.config/waybar/` | Floating top bar with VPN, battery, GPU, thermal, and health modules |
| `swaync` | `~/.config/swaync/` | Notification center & widget panel styling |
| `rofi` | `~/.config/rofi/` | Application launcher & system power menu themes |
| `ghostty` | `~/.config/ghostty/` | Ghostty terminal configuration and shaders |
| `zsh` | `~/.zshrc`, `~/.config/starship.toml` | Interactive shell environment, aliases, fuzzy finding, AI tooling integrations |
| `nvim` | `~/.config/nvim/` | LazyVim configuration, language servers, formatting rules |
| `yazi` | `~/.config/yazi/` | Fast terminal file manager config and Gruvbox theme |
| `scripts` | `~/.local/bin/` | System utilities: `safe-sysmod`, `sysmenu`, `sys-reload`, `ai-log`, `ai-ctx` |
| `theme` | `~/.config/theme/` | Master palette (`palette.json`) & Jinja-like template compiler |
| `firefox` | Flatpak profile | Custom `user.js` hardening & `userChrome.css` (dynamically linked) |
| `spotify-player` | `~/.config/spotify-player/` | Spotify TUI client settings |
| `mpv` | `~/.config/mpv/` | Video player options, auto-audio scripts, nightlight integration |
| `zathura` | `~/.config/zathura/` | Minimal document and PDF viewer styling |
| `gtk` | `~/.config/gtk-{3,4}.0/` | GTK theme, font, and icon pointers |
| `greetd` | `/etc/greetd/` | System login greeter themed to palette (stowed to `/`) |
| `dotfiles-drift` | `~/.config/dotfiles-drift/` | Systemd timer checking local dotfiles drift against git |
| `gamemode` | `~/.config/gamemode.ini` | Linux GameMode scheduler optimizations |
| `mangohud` | `~/.config/MangoHud/` | Vulkan/OpenGL performance overlay configuration |
| `paru` | `~/.config/paru/` | Paru AUR helper configuration and update-check units |
| `gemini` | `~/GEMINI.md` | Gemini AI agent system configuration & context ruleset |
| `ai-rules` | `~/` | Multi-agent rules (`.clinerules/`, `.cursor/`, `.windsurf/`, `AGENTS.md`) |

---

## ⌨️ Keybindings Reference

Default modifier key: `SUPER` (`Mod4`)

### Applications & Launchers
* `SUPER + Space` — Open Rofi Application Launcher
* `SUPER + Return` — Launch Ghostty Terminal
* `SUPER + C` — Universal Copy (terminal & GUI apps)
* `SUPER + V` — Universal Paste (terminal & GUI apps)
* `SUPER + Shift + E` — Launch Neovim (`ghostty -e nvim`)
* `SUPER + E` — Launch Yazi File Manager
* `SUPER + B` — Launch Firefox
* `SUPER + G` — AGY AI Coding Assistant
* `SUPER + K` — Keybindings Cheatsheet HUD
* `SUPER + Shift + M` — Open System Actions Menu (`sysmenu`)
* `SUPER + N` — Toggle Notification Center (`swaync`)
* `SUPER + O` — Launch Spotify
* `SUPER + A` — Audio Mixer (`pulsemixer`)
* `SUPER + I` — Wi-Fi Network Selector (`impala`)
* `SUPER + Shift + B` — Bluetooth Device Manager (`bluetui`)
* `SUPER + Shift + V` — Open clipboard history picker (`cliphist`)
* `SUPER + Shift + C` — Color picker (`hyprpicker`)

### Window Management & Tiling
* `SUPER + W` — Close active window
* `SUPER + F` — Toggle floating window
* `SUPER + P` — Toggle pseudo-tiling
* `SUPER + J` — Toggle layout split
* `SUPER + Left / Right / Up / Down` — Move window focus
* `SUPER + [0–9]` — Switch to workspace 1–10
* `SUPER + Shift + [0–9]` — Move active window to workspace 1–10
* `SUPER + S` — Toggle special workspace (*magic*)
* `SUPER + Shift + S` — Move active window to special workspace (*magic*)

### System & Screenshots
* `Print` — Fullscreen screenshot (`grim`)
* `Shift + Print` — Interactive region screenshot (`slurp`)
* `SUPER + Print` — Region screenshot + interactive annotate (`swappy`)
* `SUPER + L` — Lock session (`hyprlock`)
* `SUPER + M` — Power menu (`powermenu.sh`)

---

## 🚀 Installation & Deployment

See the comprehensive [INSTALL.md](INSTALL.md) for full system setup, dependencies, and troubleshooting.

### Quick Start

```bash
# 1. Clone dotfiles
git clone https://github.com/caueraffaini/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Dry-run simulation (verifies clean symlink targets)
./install.sh --dry-run --all

# 3. Deploy all user configurations
./install.sh --all
```

### Modular Profile Management

The [`install.sh`](install.sh) harness provides profile-based deployment and safety controls:

```bash
./install.sh --core      # Shell (Zsh), Starship, Scripts, Paru, Theme, Drift
./install.sh --wm        # Hyprland Lua, Waybar, Rofi, SwayNC, Ghostty
./install.sh --media     # MPV, Spotify-Player, Zathura, MangoHud, GameMode
./install.sh --apps      # Neovim, Yazi, Firefox Flatpak
./install.sh --system    # Root-target packages (greetd) targeting /

# Operational flags
./install.sh -n / --simulate    # Dry-run simulation (no filesystem mutations)
./install.sh -R / --restow      # Refresh symlinks and prune stale links
./install.sh -D / --delete <p>  # Unlink specific package
./install.sh -b / --backup      # Auto-backup conflicting files to *.dotfiles.bak.<ts>
```

---

## 🎨 Theming Engine (Gruvbox Material Dark)

Visual configurations inherit tokens from a Single Source of Truth (SSoT):

1. Modify [`theme/.config/theme/palette.json`](theme/.config/theme/palette.json) or any `*.template` file.
2. Validate and compile templates:
   ```bash
   # Validate token coverage without writing
   python3 theme/.config/theme/render-theme.py --check

   # Compile and trigger live desktop reload
   python3 theme/.config/theme/render-theme.py --reload
   ```
3. Live reload individual components via `sys-reload`:
   ```bash
   sys-reload theme   # Recompile palette + reload UI
   sys-reload waybar  # Validate JSONC + reload Waybar
   sys-reload hypr    # Reload Hyprland
   sys-reload all     # Reload all active desktop daemons
   ```

---

## 🛡️ Safety & Administration Tools

* **`safe-sysmod <command>`**: Wraps risky system commands in an atomic Snapper pre/post snapshot pair with instant rollback output.
* **`sys-reload [target]`**: Config validator and live reload dispatcher for Wayland daemons.
* **`dotfiles-drift`**: Systemd user service monitoring symlink drift and uncommitted state against git.
* **`ai-log <tool>`**: Transparent local AI session transcript recorder storing logs under `~/.local/share/ai-logs/`.

---

## 📄 License & Community

* **License**: [MIT](LICENSE)
* **Security Policy**: [SECURITY.md](.github/SECURITY.md)
* **Contributing & Issues**: Use [GitHub Issue Templates](.github/ISSUE_TEMPLATE/)

