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

```text
.dotfiles/
├── bin/                    # Custom scripts and utilities
├── config/                 # Application configurations (each dir is symlinked to ~/.config/<name>)
│   ├── 1Password/         # SSH agent config
│   ├── ghostty/           # Terminal emulator config
│   ├── nvim/              # Neovim configuration (Lua)
│   ├── sesh/              # Sesh session manager config (sesh.toml)
│   ├── starship/          # Shell prompt config
│   └── tmux/              # Tmux config and themes
├── git/                   # Git configuration and templates
├── install/               # Installation scripts and Brewfile
├── zsh/                   # Zsh configuration files
└── docs/                  # Integration setup and troubleshooting
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
- **File Explorer**: Snacks explorer (replaced nvim-tree)
- **Fuzzy Finder**: Snacks picker for files/buffers/help; Telescope remains for Git pickers
- **AI Assistants**: Copilot and CopilotChat
- **Git**: fugitive, gitsigns, neogit, octo.nvim
- **Formatting**: conform.nvim
- **Linting**: nvim-lint
- **Treesitter**: Syntax highlighting and text objects
- **UI**: snacks.nvim (notifier/indent/etc.), lualine

### Languages & LSPs
Configured LSP servers include:

- TypeScript/JavaScript (typescript-tools, eslint)
- Go (gopls)
- Lua (lua_ls)
- Python (pyright)
- Terraform (terraformls)
- Docker (dockerls)
- YAML (yamlls)
- JSON (jsonls)
- Markdown (markdown_oxide, harper_ls)

## Build, Test & Lint Commands

### Shell/Dotfiles

```bash
# Check Installer And Zsh Syntax
for f in install.sh install/*.zsh; do zsh -n "$f" || exit 1; done
zsh -n ~/.dotfiles/main/zsh/zshrc.symlink

# Audit The Claude Profiles (read-only)
zsh ~/.dotfiles/main/install/claude-profiles.zsh --check

# Manual Testing: Source Configuration In New Shell
source ~/.zshrc

# Install links and integrations (changes configuration)
~/.dotfiles/main/install.sh link
```

### Neovim

```bash
# No Automated Tests For Nvim Config
# Manual Testing: Open Neovim And Check For Errors
nvim +checkhealth

# Check Lua Syntax
luacheck ~/.dotfiles/main/config/nvim/

# Update And Sync Plugins
nvim --headless "+Lazy! sync" +qa
```

### Installation

```bash
# Install All Packages From Brewfile
brew bundle --file=~/.dotfiles/main/install/brewfile

# Run Full Installation Script
~/.dotfiles/main/install.sh all

# Install Tools And Create Symlinks
~/.dotfiles/main/install.sh tools
~/.dotfiles/main/install.sh link
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
- **DO NOT** use nvim-tree (replaced with Snacks explorer)
- **Fuzzy finding**: Use Snacks picker for files/buffers; preserve existing Telescope Git operations

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
  - `feat(nvim): configure Snacks picker`
  - `perf(zsh): remove duplicate compinit calls`
  - `fix(git): correct SSH signing configuration`

## Config Symlinking Convention

All directories under `config/` are symlinked to `~/.config/<name>`. When adding a new app config:

1. Create the directory at `~/.dotfiles/main/config/<appname>/`
2. Preserve or back up existing configuration before replacing its path
3. Symlink: `ln -s ~/.dotfiles/main/config/<appname> ~/.config/<appname>`

**Never create config files directly in `~/.config/`** — always source them from `~/.dotfiles/main/config/`.

## Agent Skills

- The canonical home for personal skills is [hacker1db/skills](https://github.com/hacker1db/skills), checked out at `$HOME/Developer/skills/main` by default.
- That repository provides `skillctl`, the skill manager for Codex, Claude Code, and GitHub Copilot CLI. Read its README before changing skill sources, selections, or installation behavior.
- Dotfiles does not hold or link personal skills. Do not add skills to this repository; `install/claude-profiles.zsh` runs `skillctl sync --global` for each Claude profile.
- The project-scoped Caido installer and the OpenCode skill under `config/opencode/skills/` are separate from the current `skillctl` global adapters.

## Important Files & Patterns

### Neovim Keymaps

- **Leader key**: Space
- **Local leader**: `\`
- **File operations**: `<leader>e` (Snacks explorer), `<leader>ff` (files), `<leader>fr` (recent)
- **Search**: `<leader>/` (grep), `<leader>sh` (help)
- **Buffers**: `<leader>,` (Snacks buffer picker)
- **Git**: `<leader>gc` (commits), `<leader>gb` (branches)
- **LSP**: `gd` (definition), `gr` (references), `K` (hover)
- **AI**: `:CopilotChat` and `:Copilot`; see `lua/plugins/extra/ai.lua`

### Zsh Functions
Custom functions in `zsh/functions/`, `zsh/functions.zsh`, and `zsh/git.zsh`:

- `wt-pull-all` - Fetch, add worktrees for unmerged remote branches, fast-forward every worktree, verify the default branch, and prune merged worktrees
- `c` - Quick directory navigation
- `h` - Command history search
- `yy` - Yazi file manager with directory change
- `zfetch` - Plugin fetcher

### Git Hooks
Template hooks in `git/templates/hooks/`:

- `post-checkout` - Track recent branches
- `post-merge` - Track recent merges
- `pre-commit` - Dispatch the gitleaks secret scan and JSCS/JSHint checks
- `pre-push` - Dispatch any `*.pre-push` hooks in `git/hooks/`

## Hands Off

- **NEVER** modify the Claude Code status line configuration (`~/.claude/settings.json` `statusLine` block) — the user manages this themselves

## Security & Best Practices

### Security

- **NEVER** commit secrets or API keys
- **NEVER** log or expose credentials
- **NEVER** hardcode the username in paths (e.g. `/Users/username/...`) — always use `$HOME` or `~` instead
- **Git signing**: Optional account profiles configure 1Password SSH agent signing
- **SSH agent**: Configuration lives in `config/1Password/ssh/agent.toml`
- **compinit**: Startup uses `-C`; do not assume it performs a daily security check

### Performance

- **Shell startup**: Measure locally; avoid unverified timing claims
- **Lazy loading**: Plugins load on events, not at startup
- **Completions**: Guard new external command invocations behind existence checks
- **Caching**: Use caching where possible (compinit, plugin managers)

### Compatibility

- **Platform**: macOS (darwin)
- **Shell**: Zsh, interactively and for the installer scripts
- **Terminal**: Ghostty
- **Package manager**: Homebrew

## Configuration boundaries

- The general linker skips existing configuration paths; selected managed integrations reconcile their own links.
- Personal skills are maintained outside dotfiles in the skills repository.
- lazy.nvim imports the `extra`, `git`, `ui`, `lsp`, and `mini` plugin directories. Specs directly under `lua/plugins/` are not imported by this setup.
- Use [README.md](README.md), [Claude profiles](claude/PROFILES.md) and [plan-manager integration](docs/plan-manager.md) for current setup details.

## Working With This Repository

### Before Making Changes

1. Read existing code and follow patterns
2. Check if tools/libraries are already installed (see Brewfile)
3. Review the relevant README and integration guide under `docs/`
4. Test changes in a new shell/nvim instance before committing

### Adding Neovim Plugins

1. Check if functionality already exists
2. Prefer mini.nvim ecosystem when possible
3. Create new file in appropriate `lua/plugins/` subdirectory
4. Update `lazy-lock.json` by syncing in nvim
5. Document in `lua/plugins/mini/mini.md` if using mini plugin

### Modifying Shell Config

1. Guard expensive operations with command checks
2. Avoid duplicating existing functionality
3. Test startup time with `time zsh -i -c exit`
4. Source changes before committing: `source ~/.zshrc`

## Getting Help

- Issues/Feedback: https://github.com/hacker1db/dotfiles/issues
- This is a personal dotfiles repo - adapt patterns to your own use case
