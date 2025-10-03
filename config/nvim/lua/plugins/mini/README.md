# Mini.nvim Plugins

This directory contains configuration for various mini.nvim plugins that provide lightweight alternatives to larger plugins.

## Included Plugins

### mini.ai
- **Purpose**: Better motions and textobjects
- **Replaces**: N/A (extends built-in functionality)
- **Key features**: Enhanced `a` and `i` textobjects with additional variants

### mini.surround
- **Purpose**: Modern surround replacement
- **Replaces**: tpope/vim-surround or other surround plugins
- **Key mappings**: 
  - `sa` - Add surrounding
  - `sd` - Delete surrounding
  - `sr` - Replace surrounding

### mini.comment
- **Purpose**: Comment toggling
- **Replaces**: numToStr/Comment.nvim (disabled in extra/comment.lua)
- **Key mappings**:
  - `gc` - Toggle comment
  - `gcc` - Toggle comment on current line
- **Dependencies**: Includes ts-comments.nvim for better treesitter support

### mini.pairs
- **Purpose**: Auto-pairing of brackets, quotes, etc.
- **Replaces**: windwp/nvim-autopairs (disabled in ui/autopair.lua and extra/autopair.lua)
- **Key features**: Lightweight autopairs with smart neighbor detection


### mini.statusline
- **Purpose**: Simple statusline
- **Replaces**: nvim-lualine/lualine.nvim (optional)
- **Status**: Disabled by default - set `enabled = true` to use instead of lualine
- **Key features**: Minimalist statusline with icons support

## Switching Between Plugins

To switch from the current plugins to mini equivalents:

1. **For autopairs**: The old nvim-autopairs plugins are already disabled
2. **For comments**: The old Comment.nvim plugin is already disabled
3. **For statusline**: Set `enabled = true` in `mini/statusline.lua` and `enabled = false` in `ui/lualine.lua`

## Current Exclusions

The repository previously experimented with `mini.files` (as a replacement for `nvim-tree`) and `mini.pick` (as a partial replacement for `telescope.nvim`). Both have been removed in favor of restoring:
- `nvim-tree` for the primary file explorer (`<leader>e` toggles it)
- `telescope.nvim` for all fuzzy finding (files, grep, buffers, help, git)

If re‑evaluated later, reintroduce by adding plugin specs back under this directory and restoring their keymaps.

## Configuration

Each plugin is configured with sensible defaults but can be customized by editing the respective files in this directory.
