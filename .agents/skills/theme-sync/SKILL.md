---
name: theme-sync
description: Protocol for maintaining and synchronizing Gruvbox Material Dark tokens across all template configurations and reloading active desktop components.
---

# Theme Synchronization Skill

## Overview
Centralized color palette management using `~/dotfiles/theme/.config/theme/palette.json` as the Single Source of Truth (SSoT). Automatically renders configuration files from their `*.template` counterparts.

## Theming Rules
1. **Never edit generated files directly**: Any file with a `.template` counterpart in the repository is overwritten on theme compilation.
2. **Strict Gruvbox Palette**: All color values must adhere to the Gruvbox Material Dark palette in `palette.json`.
3. **Design Tokens**:
   - Spacing: 4px, 8px, 12px, 16px, 24px.
   - Border radius: outer=10px, inner=4px, atomic=0px.
   - Accent roles: Focus `#fabd2f`, User-toggled `#fe8019`, Critical `#fb4934`, Info `#8ec07c`.

## Workflow & Commands

### 1. Update Palette
Edit `~/dotfiles/theme/.config/theme/palette.json`:
```json
{
  "bg": "#282828",
  "fg": "#ebdbb2",
  "br_yellow": "#fabd2f"
}
```

### 2. Validate & Render Templates
Validate templates without writing (dry-run check):
```bash
python3 ~/.config/theme/render-theme.py --check
```
Execute the template compiler:
```bash
~/.config/theme/render-theme.sh
# Or directly with Python and live reload:
python3 ~/.config/theme/render-theme.py --reload
# Or watch mode for continuous editing:
python3 ~/.config/theme/render-theme.py --watch --reload
```

### 3. Add a New Templated Config
1. Create `<path>/<filename>.template` using placeholder syntax `{{token_name}}` or `{{token_name_hex}}` or `{{token_name_rgb}}`.
2. Templates located in the repository are automatically discovered.
3. Run `render-theme.sh` or `python3 render-theme.py --check` to validate.

### 4. Live Reload UI Components
Reload running applications to apply updated styles:
```bash
sys-reload theme     # Recompile theme and reload all UI components
sys-reload waybar    # Reload Waybar
sys-reload hypr      # Reload Hyprland configuration
sys-reload swaync    # Reload SwayNotificationCenter
sys-reload ghostty   # Reload Ghostty terminal
sys-reload all       # Reload all supported desktop components
```

