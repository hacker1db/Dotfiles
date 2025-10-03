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

### mini.files
- **Purpose**: File explorer with Miller columns navigation
- **Replaces**: nvim-tree/nvim-tree.lua (disabled in ui/filetree.lua)
- **Key mappings**:
  - `;e` - Open file explorer
  - `h/j/k/l` - Navigate (vim-like)
  - `q` - Close explorer
  - `=` - Synchronize file system changes
  - `g?` - Show help
- **Key features**: 
  - Column view (Miller columns) for nested directory navigation
  - Preview enabled by default
  - Edit-based file manipulation (create, delete, rename, move, copy)
  - Replaces netrw as default file explorer

### mini.pick
- **Purpose**: Fuzzy finder and picker
- **Replaces**: nvim-telescope/telescope.nvim (for most use cases)
- **Key mappings**:
  - `;f` - Find files
  - `;fr` - Live grep
  - `;fc` - Grep current word
  - `;bl` - Show buffers
  - `;;` - Help tags
- **Key features**:
  - Fast fuzzy finding with minimal dependencies
  - Builtin pickers for files, grep, buffers, help
  - Used by obsidian.nvim for note picking
  - Telescope still used for git commands (commits, branches, status)

### mini.statusline
- **Purpose**: Simple statusline
- **Replaces**: nvim-lualine/lualine.nvim (optional)
- **Status**: Disabled by default - set `enabled = true` to use instead of lualine
- **Key features**: Minimalist statusline with icons support

## Switching Between Plugins

To switch from the current plugins to mini equivalents:

1. **For autopairs**: The old nvim-autopairs plugins are already disabled
2. **For comments**: The old Comment.nvim plugin is already disabled
3. **For file explorer**: mini.files is now active, nvim-tree is disabled
4. **For fuzzy finder**: mini.pick is now primary picker, telescope kept for git operations
5. **For statusline**: Set `enabled = true` in `mini/statusline.lua` and `enabled = false` in `ui/lualine.lua`

## Configuration

Each plugin is configured with sensible defaults but can be customized by editing the respective files in this directory.
