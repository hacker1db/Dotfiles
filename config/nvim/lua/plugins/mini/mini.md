# Mini.nvim plugins

lazy.nvim imports this directory through `lua/core/lazy.lua`.

| Module | Purpose | Configuration/mappings |
| --- | --- | --- |
| mini.ai | Extended textobjects | `ai.lua`; `a`/`i`, next/last variants, `g[`/`g]` |
| mini.comment | Comment toggling with ts-comments support | `comment.lua`; `gc`, `gcc` |
| mini.icons | Filetype icons and nvim-web-devicons compatibility | `icons.lua` |
| mini.pairs | Insert-mode bracket and quote pairing | `pairs.lua` |
| mini.surround | Add, delete, find, and replace surroundings | `surround.lua`; `sa`, `sd`, `sf`, `sF`, `sr` |

Snacks handles file exploration and picking: `<leader>e` for the explorer, `<leader>ff` for files, `<leader>/` for grep, `<leader>,` for buffers, and `<leader>sh` for help. Telescope remains for Git pickers. mini.files and mini.pick are not configured.

Lualine supplies the statusline; there is no mini.statusline spec to enable. The old Comment.nvim and nvim-autopairs specs have been removed.

Standalone mini.bracketed and mini.diff specs remain in the parent `lua/plugins/` directory. That directory is not imported by the current lazy.nvim setup, so these specs are not part of the active mini configuration. The mini.diff keymap in `lua/core/keymaps.lua` alone does not load its spec.
