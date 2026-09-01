# Security Policy

## Zero-Trust Repository Architecture

This repository maintains a strict **zero-secret policy**. No credentials, tokens, private keys, or machine-identifying sensitive state are tracked in version control.

### Secret Isolation Boundaries
- **WireGuard / VPN**: Configurations containing private keys reside exclusively in host-managed `/etc/wireguard/` (mode `0600`, root-owned).
- **Backups**: Restic / Rclone credentials reside exclusively in host-managed `~/.config/restic/` (mode `0700`, user-owned).
- **Sudoers Rules**: Privileged elevation drop-ins reside in `/etc/sudoers.d/` (mode `0440`, root-owned, validated via `visudo -c`).
- **Git Hook Gate**: Local `.githooks/pre-push` gate blocks pushes with uncommitted syntax or stow collisions.

## Reporting a Vulnerability

If you discover a security issue or potential secret exposure in this repository:
1. **Do NOT open a public GitHub issue.**
2. Report the vulnerability privately via GitHub Security Advisories or by contacting the repository maintainer.
3. Include details on the affected file, commit SHA, and remediation recommendations.
