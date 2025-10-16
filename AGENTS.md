# AI Agent Guidelines

This document provides context for AI coding assistants working with this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository for macOS development environment configuration. It includes:

- **Neovim config**: Lua-based configuration with mini.nvim plugins, LSP setup, and AI integration
- **Zsh config**: Shell configuration with performance optimizations, completions, and custom functions
- **Tmux config**: Terminal multiplexer with custom themes and layouts
- **Git config**: Aliases, templates, and 1Password SSH signing
- **Application configs**: Ghostty terminal, Starship prompt, 1Password SSH agent, and more

## Project Structure

```
.dotfiles/
├── bin/                    # Custom scripts and utilities
├── config/                 # Application configurations
│   ├── 1Password/         # SSH agent config
│   ├── ghostty/           # Terminal emulator config
│   ├── nvim/              # Neovim configuration (Lua)
│   ├── starship/          # Shell prompt config
│   └── tmux/              # Tmux config and themes
├── git/                   # Git configuration and templates
├── install/               # Installation scripts and Brewfile
├── zsh/                   # Zsh configuration files
└── RECOMMENDED_CHANGES.md # Known issues and improvement suggestions
```

## Key Technologies & Tools

### Development Tools
- **Editor**: Neovim (lazy.nvim plugin manager)
- **Shell**: Zsh with custom completions
- **Terminal**: Ghostty
- **Multiplexer**: Tmux
- **Package Manager**: Homebrew
- **Version Control**: Git with 1Password SSH signing
- **Node Version**: fnm (Fast Node Manager)
- **Prompt**: Starship

### Neovim Stack
- **Plugin Manager**: lazy.nvim
- **Completion**: blink.cmp (NOT nvim-cmp)
- **LSP**: Native LSP with mason.nvim for server management
- **File Explorer**: mini.files (replaced nvim-tree)
- **Fuzzy Finder**: mini.pick (replaced telescope for files/buffers)
- **AI Assistants**: avante.nvim (Claude/GPT), Copilot
- **Git**: fugitive, gitsigns, neogit, octo.nvim
- **Formatting**: conform.nvim
- **Linting**: nvim-lint
- **Treesitter**: Syntax highlighting and text objects
- **UI**: snacks.nvim (notifier/indent/etc.), lualine

### Languages & LSPs
Configured LSP servers include:
- TypeScript/JavaScript (ts_ls, eslint)
- Go (gopls)
- Lua (lua_ls)
- Python (pyright)
- Terraform (terraformls)
- Docker (dockerls)
- YAML (yamlls)
- JSON (jsonls)
- Markdown (marksman)

## Build, Test & Lint Commands

### Shell/Dotfiles
```bash
# No automated tests for dotfiles
# Manual testing: source configuration in new shell
source ~/.zshrc

# Check for zsh syntax errors
zsh -n ~/.dotfiles/zsh/zshrc.symlink

# Verify symlinks are created
~/.dotfiles/install/link.sh
```

### Neovim
```bash
# No automated tests for nvim config
# Manual testing: open Neovim and check for errors
nvim +checkhealth

# Check Lua syntax
luacheck ~/.dotfiles/config/nvim/

# Update and sync plugins
nvim --headless "+Lazy! sync" +qa
```

### Installation
```bash
# Install all packages from Brewfile
brew bundle --file=~/.dotfiles/install/brewfile

# Run full installation script
~/.dotfiles/install.sh

# Install tools and create symlinks
~/.dotfiles/install/install_tools.sh
~/.dotfiles/install/link.sh
```

## Code Style & Conventions

### General
- **NO COMMENTS** unless explicitly requested
- Follow existing patterns in the codebase
- Use existing libraries and utilities already installed
- Check Brewfile before assuming a tool is available

### Neovim Lua
- **Indentation**: 2 spaces
- **Quotes**: Double quotes for strings
- **Plugin structure**: Separate files per plugin in organized directories
  - `lua/plugins/lsp/` - LSP-related plugins
  - `lua/plugins/ui/` - UI/visual plugins
  - `lua/plugins/git/` - Git integration plugins
  - `lua/plugins/mini/` - mini.nvim ecosystem plugins
  - `lua/plugins/extra/` - Miscellaneous plugins
- **Keymaps**: Define in `lua/core/keymaps.lua` or plugin files
- **Plugin format**: Return lazy.nvim spec table
  ```lua
  return {
    "author/plugin-name",
    event = "VeryLazy",
    config = function()
      require("plugin-name").setup({
        -- config here
      })
    end,
  }
  ```
- **DO NOT** use nvim-cmp (replaced with blink.cmp)
- **DO NOT** use nvim-tree (replaced with mini.files)
- **Fuzzy finding**: Use mini.pick for files/buffers, telescope for git operations

### Shell Scripts (Zsh)
- **Indentation**: 4 spaces
- **Conditionals**: Use `[[ ]]` for tests
- **Functions**: Define in `zsh/functions/` or `zsh/functions.zsh`
- **Performance**: Always guard expensive commands (completions, evals) with existence checks
  ```zsh
  if command -v kubectl &> /dev/null; then
      source <(kubectl completion zsh)
  fi
  ```
- **Avoid duplicates**: Check for existing functionality before adding

### Git Commits
- **Format**: `type(scope): description`
- **Types**: feat, fix, perf, refactor, docs, style, test, chore
- **Scope**: nvim, zsh, tmux, git, install, etc.
- **Examples**:
  - `feat(nvim): add mini.pick fuzzy finder`
  - `perf(zsh): remove duplicate compinit calls`
  - `fix(git): correct SSH signing configuration`

## Important Files & Patterns

### Neovim Keymaps
- **Leader key**: Space
- **Local leader**: `\`
- **File operations**: `;e` (mini.files), `;f` (mini.pick files), `;fr` (recent)
- **Search**: `;/` (grep), `;;` (help tags)
- **Buffers**: `;bl` (buffer list)
- **Git**: `<leader>gc` (commits), `<leader>gb` (branches)
- **LSP**: `gd` (definition), `gr` (references), `K` (hover)
- **AI**: `<leader>aa` (avante chat), `<leader>ae` (edit), `<leader>ar` (refresh)

### Zsh Functions
Custom functions in `zsh/functions/`:
- `c` - Quick directory navigation
- `h` - Command history search
- `yy` - Yazi file manager with directory change
- `zfetch` - Plugin fetcher

### Git Hooks
Template hooks in `git/templates/hooks/`:
- `post-checkout` - Track recent branches
- `post-merge` - Track recent merges
- `pre-commit` - Run jscs/jshint checks

## Security & Best Practices

### Security
- **NEVER** commit secrets or API keys
- **NEVER** log or expose credentials
- **Git signing**: Configured with 1Password SSH agent
- **SSH approval caching**: 8 hours (28800s) in 1Password config
- **compinit security**: Runs daily check, uses `-C` flag for performance

### Performance
- **Shell startup**: Optimized to ~500ms (removed duplicates)
- **Lazy loading**: Plugins load on events, not at startup
- **Completions**: Guarded behind command existence checks
- **Caching**: Use caching where possible (compinit, plugin managers)

### Compatibility
- **Platform**: macOS (darwin)
- **Shell**: Zsh (not bash)
- **Terminal**: Ghostty (formerly Wezterm)
- **Package manager**: Homebrew

## Known Issues & TODOs

See `RECOMMENDED_CHANGES.md` for detailed list of known issues and improvement suggestions.

Key items:
1. Install script has NVM check issue (needs `nvm install --lts` before `nvm use`)
2. Consider evaluating Snacks.nvim for plugin consolidation
3. Continue monitoring shell startup performance

## Working with This Repository

### Before Making Changes
1. Read existing code and follow patterns
2. Check if tools/libraries are already installed (see Brewfile)
3. Review `RECOMMENDED_CHANGES.md` for known issues
4. Test changes in a new shell/nvim instance before committing

### Adding Neovim Plugins
1. Check if functionality already exists
2. Prefer mini.nvim ecosystem when possible
3. Create new file in appropriate `lua/plugins/` subdirectory
4. Update `lazy-lock.json` by syncing in nvim
5. Document in `lua/plugins/mini/README.md` if using mini plugin

### Modifying Shell Config
1. Guard expensive operations with command checks
2. Avoid duplicating existing functionality
3. Test startup time with `time zsh -i -c exit`
4. Source changes before committing: `source ~/.zshrc`

### Commit Checklist
- Never Commit anything let me manage the git lifecycle.
## Getting Help

- Issues/Feedback: https://github.com/sst/opencode/issues
- This is a personal dotfiles repo - adapt patterns to your own use case
