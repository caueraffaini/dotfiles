# Safety Guardrails & Operational Constraints

## Zero-Trust Secret Isolation
1. **Zero Repo Secrets**: No private keys (`id_rsa`, `id_ed25519`), WireGuard configurations, `.env` files, API tokens, or backup repository credentials may ever be committed to the repository.
2. **Host Carve-Outs**: Sensitive state resides exclusively in uncommitted, host-managed paths:
   - WireGuard configurations: `/etc/wireguard/` (root-owned, permissions `0600`).
   - Sudoers drop-ins: `/etc/sudoers.d/` (root-owned, permissions `0440`, validated via `visudo -c`).
   - Restic credentials: `~/.config/restic/` (user-owned, permissions `0700`).
   - NetworkManager drop-ins: `/etc/NetworkManager/conf.d/`.
   - Dynamic sleep hooks: `/etc/systemd/system-sleep/`.
3. **Audit Verification**: Always verify `.gitignore` excludes sensitive files before staging commits.

## System Mutation & Rollback Safeguards
1. **Snapper Snapshots (`safe-sysmod`)**: Any command modifying system state (e.g. systemd system units, package installations, kernel configurations, filesystem modifications) must be wrapped using `safe-sysmod <command>` to create pre/post snapshot pairs.
2. **Read-Only Verification**: Execute read-only diagnostics first (`status`, `cat`, `readlink`, `test`) before mutating configuration.
3. **No Direct System Package Invocations**: Do not invoke `pacman`, `yay`, or `paru` in automated pipelines without explicit human instruction.

## Configuration Integrity & Theming Invariants
1. **Template Source-of-Truth**: Never edit generated theme targets directly (e.g. `waybar/style.css`, `rofi/config.rasi`, `swaync/style.css`, `hyprlock.conf`). Always modify the respective `*.template` file and re-render via `render-theme.py`.
2. **Hyprland Modular Lua**: Maintain the Lua architecture. Do not introduce monolithic legacy `.conf` structures for Hyprland.
3. **Drift & Stow Validation**: Before pushing any changes, test Stow linking using `./install.sh -n`. Ensure no files conflict or break existing symlinks.
4. **Git Hook Enforcement**: Ensure `.githooks/pre-push` checks pass cleanly:
   - Stow simulation: `./install.sh -n`
   - Shell syntax verification: `bash -n` across all tracked `.sh` and shebang scripts.
   - Lua syntax verification: `luac -p` across all tracked `*.lua` files.
