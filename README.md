# Dotfiles

macOS development environment — modular installer, theme manager, 40+ Neovim plugins, and per-repo Git identity overrides.

## Quick Start

```bash
git clone https://github.com/hacker1db/Dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh all
```

Re-run individual steps safely (idempotent):

```bash
./install.sh backup      # backup existing dotfiles
./install.sh link        # create/update all symlinks
./install.sh terminfo    # install terminfo entries
./install.sh homebrew    # Homebrew + Brewfile packages
./install.sh shell       # zsh setup
./install.sh git         # git auth & credential helpers
./install.sh macos       # macOS defaults
./install.sh extras      # extra tools/scripts
./install.sh theme       # theme manager (list/apply/sync)
```

`./install.sh all` runs them in order. Non-interactive mode for CI:

```bash
DOTFILES_NONINTERACTIVE=1 ./install.sh git
```

## What's Included

### Shell (Zsh)

- **Prompt:** Starship with custom config (`config/starship/starship.toml`)
- **Plugins:** fzf-tab (via zfetch plugin manager)
- **Completions:** kubectl, limactl, 1Password CLI — all behind `command -v` guards
- **Node management:** fnm with auto-switch on `cd`
- **Navigation:** zoxide (aliased to `cd`)
- **Listing:** eza with icons and git status (`ll`, `l`)
- **FZF:** fd-backed file finder with custom color scheme
- **119 aliases** across navigation, git, docker, azure, AI tools, and more
- **30+ functions** including `extract`, `ghmerge`, `gitsign`, `jwt` decode, tmux helpers
- **Local overrides:** `~/.localrc` sourced if present

### Neovim

Location: `config/nvim/` — lazy.nvim plugin manager, organized by category.

| Category | Plugins |
|----------|---------|
| **Completion** | blink.cmp, LuaSnip (markdown templates from SecondBrain vault) |
| **LSP** | mason.nvim, lspsaga (finder, diagnostics, calls, outline), lspconfig |
| **Languages** | TypeScript tools, gopher.nvim (Go), markdown-oxide, harper-ls (grammar) |
| **Formatting** | conform.nvim |
| **Linting** | nvim-lint (markdownlint gutter-only, no virtual text) |
| **Git** | fugitive, gitsigns, neogit, octo (GitHub PRs/issues) |
| **UI** | snacks.nvim (explorer, picker, dashboard, notifier, indent, zen, terminal, lazygit), lualine, noice.nvim, which-key, trouble.nvim |
| **Treesitter** | Full parsing with per-filetype fold overrides (markdown, PowerShell, JSON) |
| **Telescope** | Git-specific pickers and extensions |
| **Mini** | ai, comment, icons, pairs, surround, bracketed, diff |
| **Extras** | Copilot, obsidian.nvim, render-markdown, colorizer, rainbow delimiters, todo-comments, undotree, maximizer |
| **Debug** | DAP configuration |
| **Theme** | Eldritch with custom diagnostic/heading highlights |

**Snippets:** UltiSnips templates for markdown, TypeScript, HTML, JavaScript, gitcommit, vim, textile.

```bash
nvim --headless "+Lazy! sync" +qa   # headless plugin sync
nvim +checkhealth                    # verify setup
```

### Tmux

Config: `config/tmux/tmux.conf` — transparent status bar, vi-mode, mouse support.

**Plugins (TPM):** sensible, resurrect, continuum (auto-save/restore), yank, battery, cpu, fzf-url, vim-tmux-navigator, nerd-font-window-name.

**Features:** seamless Neovim/tmux navigation (hjkl), lazygit popup, gitmux status integration.

### Ghostly Terminal

Config: `config/ghostty/config` — 78% opacity with blur, JetBrains Mono 14pt italic with ligatures, linkarzu color theme, URL detection.

### Git

- **Global config:** `git/gitconfig.symlink` with SSH commit signing via 1Password (`gpg.format=ssh`)
- **Local overrides:** `~/.gitconfig-local` auto-linked from `~/Developer/clitools/` if present, otherwise stub created
- **Global ignore:** `git/gitignore_global.symlink`
- **Hooks:** pre-commit (jscs, jshint), post-merge templates
- **Multi-account:** interactive work/personal switching in `install/git.sh`

### Homebrew

`install/install_tools.sh` manages:

- **100+ formulas:** git, gh, neovim, go, rust, node, fzf, ripgrep, bat, eza, fd, starship, zoxide, tmux, lazygit, kubectl, k9s, helm, terraform, azure-cli, trivy, grype, trufflehog, pandoc, hugo, and more
- **70+ casks:** Ghostty, Claude, 1Password, Obsidian, Docker Desktop, Cursor, Figma, Discord, Postman, Azure Data Studio, OBS, and more
- **30+ taps:** 1password, azure, docker, hashicorp, oven-sh (bun), and more

### Claude Code

`claude/` directory symlinked to `~/.claude/` during install:

- **19 agents** (oh-my-claudecode orchestration)
- **15 custom commands**
- **MCP server config** (`mcp.json`)
- **HUD display** and statusline customization

### Custom Scripts (`Bin/`)

| Script | Purpose |
|--------|---------|
| `e` | Editor shortcut |
| `tm` | Tmux session manager |
| `jwt` | JWT token decoder |
| `git-bare-clone` | Enhanced bare repo cloning |
| `git-kill` | Branch cleanup |
| `git-recent` | Recent commit viewer |
| `gbrt` | Git bare repo tool |
| `tmux-reload-all` | Reload all tmux sessions |
| `dotnet-install.sh` | .NET SDK installer |

### MacOS Defaults

`install/osx.sh` sets: Finder preferences, Dock behavior, keyboard repeat rates, terminal encoding, and UI tweaks.

### NvimTmux.App

`install/nvimtmux.sh` creates a custom macOS app that opens files in Neovim inside tmux. Registers file associations via `duti` for 20+ file types.

## Symlink Strategy

All `*.symlink` files are linked into `$HOME` with a leading dot (e.g., `zshrc.symlink` → `~/.zshrc`). Directories under `config/` are linked to `~/.config/<name>/`. Claude Code configs are linked to `~/.claude/`.

Re-running `./install.sh link` reconciles all symlinks, including vim compatibility links (`~/.vimrc`, `~/.vim`) and `~/.gitconfig-local`.

## Theme Manager

```bash
./install.sh theme list           # list available themes
./install.sh theme apply Eldritch # apply named theme
./install.sh theme current        # show current theme
./install.sh theme sync           # re-write integrations
```

Applies across: Neovim colorscheme, Starship palette, Ghostty color scheme, tmux theme.

## Safety

No secrets stored in repo. 1Password SSH agent handles commit signing and authentication.

---

Feel free to fork and adapt.
