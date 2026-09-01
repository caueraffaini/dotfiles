# 🛠️ Installation & Setup Guide

This guide walks through configuring a fresh Arch Linux system with these dotfiles.

---

## 1. Prerequisites & Base System

Ensure your Arch Linux installation is updated with base development packages and Git:

```bash
sudo pacman -Syu --needed base-devel git stow zsh
```

### Install an AUR Helper (e.g. `paru` or `yay`)
```bash
git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
cd /tmp/paru-bin && makepkg -si
```

---

## 2. Package Dependencies

Install core desktop, compositor, terminal, and utility packages:

```bash
paru -S --needed \
  hyprland \
  ghostty-git \
  waybar \
  swaync \
  rofi-wayland \
  starship \
  eza \
  bat \
  fd \
  fzf \
  vivid \
  grim \
  slurp \
  swappy \
  wl-clipboard \
  cliphist \
  playerctl \
  libnotify \
  jq \
  wlsunset \
  yazi \
  zathura \
  zathura-pdf-mupdf \
  mpv \
  ttf-jetbrains-mono-nerd \
  ttf-atkinson-hyperlegible \
  gruvbox-material-gtk-theme-git \
  gruvbox-plus-icon-theme-git \
  bibata-cursor-theme
```

---

## 3. Clone and Deploy Dotfiles

Clone into `~/dotfiles`:

```bash
git clone https://github.com/caueraffaini/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Dry-Run Simulation (Recommended)
Simulate symlink creation to detect any potential file collisions before applying:
```bash
./install.sh --simulate --all
```

### Deploy Package Profiles
Deploy user configurations into `$HOME`:
```bash
# Deploy all standard user packages + Flatpak Firefox links
./install.sh --all

# Or deploy specific profiles:
./install.sh --core      # Shell (Zsh), Starship, Scripts, Theme, Paru
./install.sh --wm        # Hyprland Lua, Waybar, Rofi, SwayNC, Ghostty
./install.sh --media     # MPV, Spotify-Player, Zathura, MangoHud, GameMode
./install.sh --apps      # Neovim, Yazi, Firefox
```

If conflicting untracked files are reported, run with `-b` / `--backup` to auto-backup existing files:
```bash
./install.sh --backup --all
```

---

## 4. Display Manager (`greetd` + `tuigreet`)

To configure the themed `greetd` login prompt:
```bash
paru -S --needed greetd greetd-tuigreet
sudo systemctl enable greetd.service

# Deploy greetd configuration to /etc/greetd/
./install.sh --system
```

---

## 5. Flatpak Firefox Configuration

If using the Firefox Flatpak (`org.mozilla.firefox`):
```bash
flatpak install flathub org.mozilla.firefox
# Run Firefox once to initialize the profile directory
flatpak run org.mozilla.firefox &
# Link user.js and userChrome.css
./install.sh firefox
```

---

## 6. Theme Compilation & Hot Reload

Compile all design tokens from `palette.json` into active desktop configurations:
```bash
python3 theme/.config/theme/render-theme.py --reload
```

---

## 7. Troubleshooting & Maintenance

- **Symlink Drift:** Check drift status anytime using `dotfiles-drift`:
  ```bash
  ~/.config/dotfiles-drift/drift-check.sh
  ```
- **Live Reload:** Trigger a full desktop reload without restarting session:
  ```bash
  sys-reload all
  ```
- **Kernel / Secure Boot:** If using `sbctl` and Secure Boot, re-sign after kernel updates:
  ```bash
  sudo mkinitcpio -P && sudo sbctl sign-all && sudo sbctl verify
  ```
