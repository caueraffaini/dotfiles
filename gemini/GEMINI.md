# GEMINI.md - Arch Linux Polish (Gruvbox Material)

Condensed agent ruleset. Master context is maintained in `.agents/rules/project-context.md` and `.agents/rules/safety-guardrails.md`.

## System Overview
Arch Linux Power User — dev, AI/ML, gaming (Proton), research. Aesthetic: Gruvbox Material Dark (warm earthy). Prioritize security, recoverability, performance. Config home dir, not software project.


## System Architecture
- **Host**: Arch Linux (`paru`). Boot: UEFI → Limine → LUKS2 (TPM2 PCR 0+7 auto-unlock) → Btrfs.
- **Secure Boot**: enforced via `sbctl`. Kernel/initramfs change → `sudo mkinitcpio -P && sudo sbctl sign-all && sudo sbctl verify` (all three; unsigned = no boot).
- **TPM2 PCR 0+7**: Secure Boot / bootloader / firmware change breaks auto-unlock until re-enrolled.
- **Storage**: Btrfs subvols `@`, `@home`, `@snapshots`, `@var_log`, `@var_cache`, `@var_tmp`, `@swap`, `@containers`. Opts `noatime,compress=zstd:3,ssd,discard=async,space_cache=v2`.
- **Runtime**: native host, no container. Gemini CLI `/usr/bin/gemini` (npm global `@google/gemini-cli`), Antigravity CLI (`agy`). `sudo` = real host sudo.

## Hardware
- **CPU/GPU**: AMD Ryzen 7 7735HS (8C/16T) / Radeon 680M (RDNA2 iGPU).
- **Mem**: 19 GiB RAM, 23 GiB swap, 476 GiB disk (LUKS2 Btrfs).
- **Displays** (`hypr/modules/monitors.lua`): `eDP-1` scale 1.25 @ `1920x120`; `HDMI-A-1` (Philips TV) @ `0x0`; bottom-aligned via y=120. `auto` fallback. Clamshell lid handler (`~/.config/hypr/scripts/lid-handler.sh`) migrates eDP-1 workspaces to external monitor on close, restores on open.
- **Keyboards** (`hypr/modules/input.lua`): global `kb_layout=br` (ABNT2, internal); external forced `us`+`intl` per-device (dongle/BT/USB blocks).
- **Thermals**: `~/.config/waybar/k10temp` and `/tmp/waybar-k10temp` symlinks regenerated per-boot by `link-k10temp.sh` (hwmon numbers shuffle on reboot).

## Window System
Hyprland (Wayland), **Lua config not legacy `.conf`** — entry `~/.config/hypr/hyprland.lua`, modules `hypr/modules/` (monitors, env, autostart, appearance, input, keybinds, rules). `dwindle` layout. Terminal Ghostty (`SUPER+Return`), universal copy/paste (`SUPER+C` / `SUPER+V`), launcher `rofi -show drun` (`SUPER+Space`), cheatsheet `keybinds-hud.py` (`SUPER+K`), agy CLI (`SUPER+G`), editor `nvim` (`SUPER+SHIFT+E`), clipboard `cliphist` (`SUPER+SHIFT+V`), spotify (`SUPER+O`), file mgr `yazi` (`SUPER+E`). Login: greetd + tuigreet → `start-hyprland`. Bar: Waybar (top floating). `hl.timer` unreliable in Lua runtime — use background bash loops for periodic tasks.

## Power & Idle
- **AC**: `performance`, hypridle killed (no idle actions), restore brightness.
- **Battery**: `balanced` once (manual `powerprofilesctl set` after respected). `power-sync.sh` (10 s bash loop) owns hypridle lifecycle + profile→config swap within 10 s:
  | profile | lock | screen-off | hibernate |
  |---------|------|-----------|-----------|
  | performance | 10 m | 15 m | 30 m |
  | balanced | 5 m | 8 m | 12 m |
  | power-saver | 2 m | 4 m | 8 m |
- **Hibernate only — no suspend.** `systemctl hibernate`; resume preconfigured in kernel cmdline.
- **zram swap (prio 100).** `zram-generator` → `/etc/systemd/zram-generator.conf` (zram0, `ram/2` ≈9.6G, zstd). Hot pages → RAM-compressed first; disk `/swap/swapfile` (prio -1) untouched = hibernate target (resume is cmdline-driven, zram never holds hibernate image). `/etc/sysctl.d/99-zram.conf`: `vm.page-cluster=0`, `vm.swappiness=100`. Root-owned host carve-outs, not stowed. Don't lower zram prio below swapfile or drop swapfile (breaks hibernate).
- **Low battery**: ≤20% → notify + dim to 30%; <10% → notify + brightness 0. Restore on AC plug.
- `~/.config/hypr/hypridle.conf` NOT stowed — runtime symlink managed by `power-sync.sh` → active profile config. Do not stow or hand-edit.
- `hypridle -c` flag broken v0.1.7 (crashes if default `hypridle.conf` absent). `power-sync.sh` symlink-swaps profile config to `hypridle.conf` then runs **plain `hypridle`**. Do not use `hypridle -c`; do not start hypridle standalone.
- `hyprctl reload` does NOT re-fire autostart. Apply `power-sync.sh` changes live (on host): `killall power-sync.sh hypridle; ~/.config/hypr/scripts/power-sync.sh &`.
- `/etc/systemd/system-sleep/fix-keyboard` — root-owned host file (outside dotfiles). Dynamic atkbd rebind on resume post-hibernate, fixes internal keyboard death. Edit only via `sudo` on host.
- `/etc/systemd/logind.conf` `HandlePowerKey=ignore` — power button routes Hyprland `XF86PowerOff`→`powermenu.sh`. Don't revert without updating binding.

## Audio
System-wide AC3 transcode via Pipewire (`~/.config/pipewire/hdmi-ac3.conf`). **Philips TV accepts AC3 or LPCM 2.0 only** — all surround must transcode AC3. Do not disable transcode without replacement path.

## DNS & VPN
- **DNS**: systemd-resolved + DoT → AdGuard (`/etc/systemd/resolved.conf` `DNSOverTLS=yes`, fail-closed). NM hands off via `/etc/NetworkManager/conf.d/dns.conf`. Captive portals need temp `opportunistic`.
- **VPN**: ProtonVPN free, raw WireGuard (AUR CLIs = dep-hell). `/etc/wireguard/proton-us.conf` (root 600) from Proton config with **`DNS =` line stripped** (else conflicts strict DoT). Connect `sudo wg-quick up proton-us`/`down`. Waybar toggle `custom/vpn` needs `/etc/sudoers.d/wg-proton` (root 0440, scoped 2 exact cmds, `visudo -c` validated).
- `resolved.conf`, NM drop-in, WG config, sudoers drop-in = root-owned host carve-outs **outside dotfiles**, not committed (WG holds private key).

## Theming (Gruvbox Material Dark — ONLY, no exceptions)
- Single palette source `~/.config/theme/palette.json`. Render `~/.config/theme/render-theme.sh`.
- **Edit the `.template`, NEVER rendered output** — render-theme overwrites generated files silent. Templated: ghostty/hyprlock/appearance.lua/mpv/rofi/swaync style/waybar style/yazi theme/zathura/starship/**greetd config.toml** (`*.template` → generated).
- **Design tokens (drift breaks system):** spacing `4/8/12/16/24` only (never 5/6/7/14/20). Radius `outer=10` / `inner=4` / `atomic=0`. Accents: `br-yellow #fabd2f`=active focus, `br-orange #fe8019`=user-toggled, `br-red #fb4934`=critical only, `br-aqua #8ec07c`=info. Motion `220ms cubic-bezier(0.32,0.72,0,1)`.
- GTK 3/4 CSS does **not** support `font-variant-numeric` — don't add. Waybar glyphs = literal UTF-8 Nerd Font codepoints.
- Fonts: JetBrainsMono Nerd (mono), Atkinson Hyperlegible 11 (UI). GTK `Gruvbox-Material-Dark`, icons `Gruvbox-Plus-Dark`, cursor `Bibata-Modern-Classic` 24.

## Firefox
Flatpak `org.mozilla.firefox` (SUPER+B). `firefox` dotfiles pkg = **manual symlinks** (dynamically detected profile via `install.sh`) into `~/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release/` (profiles.ini, user.js, chrome/userChrome.css). `user.js`=Betterfox v150 + legacy-stylesheets gate. `userChrome.css`=Gruvbox restyle. Full Flatpak restart to apply (no live reload).

## Dotfiles (GNU Stow @ `~/dotfiles`)
- Repo `github.com:caueraffaini/dotfiles` (SSH). Pkgs: `ai-rules dotfiles-drift gamemode gemini ghostty gtk hypr mangohud mpv nvim paru rofi scripts spotify-player swaync theme waybar yazi zathura zsh`. All `~/.config/<pkg>` paths = symlinks into `~/dotfiles/<pkg>/`.
- **Bootstrap/redeploy:** `cd ~/dotfiles && ./install.sh [pkg…] [-R|--restow | -D|--delete | -n|--simulate]`. Wraps `stow -t $HOME` for standard packages, `sudo stow -t /` for `greetd` (root target → `/etc/greetd/`), and dynamic Flatpak-profile symlinks for `firefox`. No args = deploy everything. `README.md` and `install.sh` are repo-meta — never passed to stow. `dotfiles-drift` ships the daily stow-link/git drift detector (script + systemd user units).
- **Stow (native host):** plain `stow` works; prefer `./install.sh <pkg>` (auto-detects stow binary).
- **Pre-push gate (A3a):** tracked hook `~/dotfiles/.githooks/pre-push` blocks pushes that fail `./install.sh -n` (stow sim), `bash -n` (every tracked `*.sh`/shebang script incl extension-less `scripts/.local/bin/*`), or `luac -p` (`*.lua`, syntax-only — `hl` has no offline linter); `shellcheck`/`luacheck` run **ADVISORY only — print, never block**; `.luacheckrc` at repo root declares runtime globals (`hl`,`vim`) + excludes vendored samples. Hard block = stow conflict + `bash -n` + `luac -p` only.
- Re-stow only when **new files added** (existing symlinks already point in repo — editing repo file enough). Confirm target: `readlink -f ~/.config/<pkg>/<file>`.
- **New package:** `mkdir`+`mv` into `~/dotfiles/<pkg>/`, then **add `<pkg>` to `STD_PKGS` in `~/dotfiles/install.sh`**, then `stow -t $HOME <pkg>`.
- **Do NOT stow** `restic/`, `rclone/` (tokens/passwords). `hypridle.conf` untracked (runtime symlink).

## Git
`~/.gitconfig`: name/email set, `core.editor=nvim`, `init.defaultBranch=main`, `pull.rebase=true`, `push.autoSetupRemote=true`, all commits SSH-signed (`~/.ssh/id_ed25519`). Host `openssh` required. **Commit convention: strict Conventional Commits `type(scope): subject`** — type ∈ `feat|fix|docs|refactor|chore`, scope = dotfiles pkg name.

## Shell (Zsh)
Aliases shadow coreutils: `cat`→`bat`, `ls`→`eza`, `find`→`fd`. ⚠ Non-interactive shells don't load `.zshrc` aliases — bare `ls`/`find`/`cat` = real coreutils. Still use `/usr/bin/ls`, `/usr/bin/find`, `/bin/cat` in scripts/heredocs for deterministic behavior. Tools: starship, fzf, rg, vivid.

## Misc Subsystems
- **Clipboard**: `wl-paste --watch cliphist store` (autostart, text+img); universal copy `SUPER+C`, universal paste `SUPER+V`, history picker `SUPER+SHIFT+V`.
- **Bluetooth persistence**: `AutoEnable=true` + `systemd-rfkill` masked; `rfkill unblock bluetooth` autostart fallback.
- **swaync**: `swaync.service` masked. Autostart sole owner (autostart.lua).
- **Restic backups** (host-only, NOT stowed): `restic-backup.service` (daily) → `~/.config/restic/backup.sh`. `custom/backup` module in Waybar reads local systemd state + journal only.
- **Spotify**: `spotify-player` (`app.toml` config, TUI player).

## Gaming
- **Stack (native, multilib):** `steam` (native, Steam Linux Runtime), `lutris`, `mangohud`+`lib32-mangohud`, `gamescope`, `gamemode`+`lib32-gamemode`, `vulkan-mesa-layers`+lib32. Proton-GE = AUR `protonup-rs`.
- **Stowed pkgs:** `mangohud` (`~/.config/MangoHud/MangoHud.conf`, static Gruvbox hex), `gamemode` (`~/.config/gamemode.ini`).
- **⚠ gamemode ↔ power-sync.sh governor conflict:** power-sync.sh owns governor (AC→performance, battery→balanced). Game on AC.
- **External games SSD:** WD SN740 512G in RTL9210C USB enclosure (`/dev/sda`). Whole-disk LUKS2, Btrfs `LABEL=games`, subvols `@games`/`@data`/`@snapshots`.

## Constraints & Utilities
- **Reload tool:** `sys-reload [waybar|hypr|swaync|power-sync|all]` (stowed `scripts` pkg, `~/.local/bin/sys-reload`) — validates waybar JSONC before reload. `config-guard.service` watches configs via inotify.
- **System-health Waybar module:** `custom/syshealth` (waybar pkg, `scripts/syshealth.sh`).
- **`sysmenu`** (`scripts` pkg, `~/.local/bin/sysmenu`, `SUPER+SHIFT+M`) — rofi system-actions sheet.
- **`safe-sysmod <cmd…>`** (`scripts` pkg, `~/.local/bin/safe-sysmod`) — atomic Snapper pre/post snapshot wrapper.
- **`ai-log <tool>`** (`scripts` pkg, `~/.local/bin/ai-log`) — session transcript recorder (`~/.local/share/ai-logs/`).
- **`ai-ctx [path|show|init]`** (`scripts` pkg, `~/.local/bin/ai-ctx`) — per-project context discovery tool.

## Operational Guidelines
1. **Safety**: confirm destructive/`sudo` ops before running.
2. **Maintenance**: re-sign sbctl after kernel/initramfs (`sudo mkinitcpio -P && sudo sbctl sign-all && sudo sbctl verify`).
3. **Consistency**: Gruvbox Material Dark only.
4. **Workflow**: stow (if new files) → conventional `git commit` → `push`.
5. **Risk**: Btrfs snapshot (host via `safe-sysmod`) before risky system mods.
