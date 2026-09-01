# Project Context: Arch Linux Dotfiles

## Architecture & System Baseline
- **Distribution**: Arch Linux (`paru` AUR helper, multilib enabled).
- **Storage**: Btrfs on LUKS2 encryption (subvolumes: `@`, `@home`, `@snapshots`, `@var_log`, `@var_cache`, `@var_tmp`, `@swap`, `@containers`). Mount options: `noatime,compress=zstd:3,ssd,discard=async,space_cache=v2`.
- **Boot & Security**: UEFI -> Limine -> LUKS2 (TPM2 PCR 0+7 auto-unlock). Secure Boot enforced via `sbctl`.
- **Kernel / Initramfs Maintenance**: Any kernel/initramfs update requires `sudo mkinitcpio -P && sudo sbctl sign-all && sudo sbctl verify`. Unsigned binaries will fail to boot.
- **Power & Hibernation**: Hibernation supported via disk swapfile (`/swap/swapfile`, prio -1); zram0 (`ram/2`, zstd, prio 100) handles active hot paging. System sleep uses hibernation (`systemctl hibernate`), not suspend.

## Dotfiles Management (GNU Stow)
- **Repo Location**: `~/dotfiles` (tracked via Git, Conventional Commits `type(scope): subject`).
- **Engine**: GNU Stow wrapper `~/dotfiles/install.sh`.
  - Standard packages: Stowed into `$HOME` (`stow -t $HOME <pkg>`).
  - System packages: `greetd` stowed into `/` (`sudo stow -t / greetd`).
  - Browser profile: `firefox` dynamically links `user.js`, `profiles.ini`, and `userChrome.css` into the Flatpak profile directory (`~/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release/`).
- **Drift Monitoring**: `dotfiles-drift.service` and `dotfiles-drift.timer` run daily drift checks via `~/.config/dotfiles-drift/drift-check.sh` and notify on unlinked or uncommitted divergence.
- **Pre-Push Validation**: `~/dotfiles/.githooks/pre-push` enforces clean stow simulation (`./install.sh -n`), shell script syntax (`bash -n`), and Lua syntax (`luac -p`) before pushes are accepted.

## Window System & Desktop Environment
- **Compositor**: Hyprland (Wayland) configured exclusively in Lua (`~/.config/hypr/hyprland.lua`), loading modular components from `~/.config/hypr/modules/`:
  - `monitors.lua`: Display arrangements, scaling, and clamshell display routing.
  - `env.lua`: Wayland / XDG / toolkit environment variables.
  - `autostart.lua`: Daemons, polkit agent, cliphist, notifications, and services.
  - `appearance.lua`: Window borders, gaps, animations, and Gruvbox color tokens.
  - `input.lua`: Keyboard layouts (ABNT2 `br` internal, `us/intl` per-device external) and trackpad gestures.
  - `keybinds.lua`: Window management, application launchers, and utility shortcuts.
  - `rules.lua`: Window and layer rules (dialogs, float rules, PiP routing).
- **Display Manager**: `greetd` running `tuigreet` launching `start-hyprland`.
- **Status Bar**: `waybar` (top floating bar) with custom JSONC configuration, CSS styling, and sensor polling scripts (`syshealth.sh`, `backlight.sh`, `battery.sh`, `link-k10temp.sh`, `vpn.sh`).
- **Notification Daemon**: `swaync` (SwayNotificationCenter) configured with Gruvbox stylesheet.
- **Application Launcher**: `rofi` with Wayland support (`rofi-wayland`).
- **Terminal Emulator**: `ghostty` configured with JetBrainsMono Nerd Font.

## Design System & Theming
- **Theme**: Gruvbox Material Dark (Warm Earthy).
- **Single Source of Truth**: `~/dotfiles/theme/.config/theme/palette.json`.
- **Template Engine**: `render-theme.py` / `render-theme.sh`. Never edit generated config files directly if a `*.template` counterpart exists; update the template and re-render.
- **Design Tokens**:
  - Spacing grid: `4px`, `8px`, `12px`, `16px`, `24px` only.
  - Border radius: Outer container = `10px`, Inner child/element = `4px`, Atomic = `0px`.
  - Accent roles: Active focus (`#fabd2f` / `br_yellow`), User toggled (`#fe8019` / `br_orange`), Critical (`#fb4934` / `br_red`), Info (`#8ec07c` / `br_aqua`).
  - Typography: JetBrainsMono Nerd Font (monospace/terminal), Atkinson Hyperlegible (UI/desktop).

## Local Utilities & Scripts (`~/.local/bin/`)
- `safe-sysmod <command>`: Wraps system commands in Snapper pre/post snapshot pairs for instant rollback.
- `sys-reload [target]`: Validates configs (e.g. Waybar JSONC) and signals running daemons to reload.
- `ai-ctx [path|show|init]`: Context discovery utility across repository workspaces.
- `ai-log <command>`: Session transcript capture into `~/.local/share/ai-logs/`.
- `sysmenu`: Rofi-based system action sheet.
