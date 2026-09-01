-- Lua LSP tuning for this machine's Hyprland Lua configs.
-- Hyprland's Lua runtime injects the global `hl` (see ~/.config/hypr/modules/*),
-- which lua_ls otherwise flags as undefined-global on every line. Neovim/`vim`
-- globals are already handled by LazyVim's lazydev; this only adds `hl`.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "hl" },
              },
            },
          },
        },
      },
    },
  },
}
