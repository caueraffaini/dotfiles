---
name: dotfiles-stow
description: Operational runbook for GNU Stow dotfiles management — package creation, restowing, simulation, conflict resolution, and pruning.
---

# GNU Stow Dotfiles Management Skill

## Overview
Manage symlinks between the `~/dotfiles` repository and the host system using GNU Stow and the repository wrapper `~/dotfiles/install.sh`.

## Core Workflows

### 1. Simulation & Dry Run (Safe Check)
Always simulate stow operations before executing:
```bash
./install.sh -n
# Or for a specific package:
./install.sh -n <package_name>
```

### 2. Standard Deployment & Restow
Deploy all standard user packages:
```bash
./install.sh
# Or specify profile groups:
./install.sh --core
./install.sh --wm
./install.sh --media
./install.sh --apps
./install.sh --system    # Root-target packages (greetd)
```
Restow (re-link / fix drift for all or specific packages):
```bash
./install.sh -R
./install.sh -R hypr waybar
```

### 3. Adding a New Package
To onboard a new application configuration:
1. Create the package directory mirroring the `$HOME` path:
   ```bash
   mkdir -p ~/dotfiles/<pkg>/.config/<pkg>
   mv ~/.config/<pkg>/* ~/dotfiles/<pkg>/.config/<pkg>/
   ```
2. Add `<pkg>` to appropriate group (`GRP_CORE`, `GRP_WM`, `GRP_MEDIA`, or `GRP_APPS`) inside `~/dotfiles/install.sh`.
3. Stow the package:
   ```bash
   ./install.sh <pkg>
   ```
4. Verify symlink resolution:
   ```bash
   readlink -f ~/.config/<pkg>
   ```

### 4. Conflict Resolution & Automated Backup
If Stow reports conflicts with existing untracked files:
1. Run `./install.sh -b <pkg>` to automatically move conflicting files to `<path>.dotfiles.bak.<timestamp>`.
2. Alternatively, manually back up or remove the target file:
   ```bash
   mv ~/.config/<conflicting_file> ~/.config/<conflicting_file>.bak
   ```
3. Re-run `./install.sh <pkg>`.

### 5. Deleting / Unstowing a Package
To remove symlinks for a package:
```bash
./install.sh -D <pkg>
```

