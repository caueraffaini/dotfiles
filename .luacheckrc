-- luacheck config for the dotfiles repo. The pre-push hook runs luacheck
-- ADVISORY (non-blocking); this just removes false positives so the
-- advisory output is actually meaningful.
std = "lua54"

-- Runtime-injected globals these configs legitimately use:
--   hl      -> Hyprland Lua config runtime (no offline linter exists)
--   vim     -> Neovim
--   mp      -> mpv Lua scripting runtime
--   awesome, client, screen -> (future-proof, harmless if unused)
read_globals = { "hl", "vim", "mp", "awesome", "client", "screen" }
globals      = { "vim" }            -- Neovim configs mutate vim.*

max_line_length = 120

-- Vendored / sample files shipped by upstream templates, not ours to lint:
exclude_files = {}

