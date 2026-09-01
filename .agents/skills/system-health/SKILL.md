---
name: system-health
description: Operational runbook for auditing systemd user services, verifying dotfiles symlink drift, checking Btrfs snapshot states, and validating Secure Boot signatures.
---

# System Health & Integrity Skill

## Overview
Diagnostic runbook for verifying system state, service health, dotfiles drift, and boot security on Arch Linux.

## Diagnostic Procedures

### 1. Dotfiles Drift & Symlink Verification
Check whether live configs have diverged from tracked repository files:
```bash
~/.config/dotfiles-drift/drift-check.sh
```
Or check systemd timer status:
```bash
systemctl --user status dotfiles-drift.timer
systemctl --user status dotfiles-drift.service
```

### 2. Systemd User Services & Timers
Inspect the active user automation services:
```bash
# Package update check timer
systemctl --user status paru-check.timer

# Config change watcher / syntax guard
systemctl --user status config-guard.service
```

### 3. Btrfs Snapshot Consistency
Audit local Snapper snapshots across subvolumes:
```bash
sudo snapper -c root list
```
Run risky system modifications safely with automatic pre/post snapshots:
```bash
safe-sysmod <command>
```

### 4. Secure Boot & Unified Kernel Signatures
Verify kernel signing status before rebooting after any kernel/initramfs update:
```bash
sbctl status
sbctl verify
```
If signatures are missing or outdated:
```bash
sudo mkinitcpio -P && sudo sbctl sign-all && sudo sbctl verify
```

### 5. Waybar & Desktop Sensor Health
Inspect system health indicators:
```bash
~/.config/waybar/scripts/syshealth.sh
~/.config/waybar/scripts/backup.sh
~/.config/waybar/scripts/vpn.sh
```
