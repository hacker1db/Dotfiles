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

### Global AI instructions

Edit root `AGENTS.md` for dotfiles repository guidance. Edit `global/AGENTS.md` for shared global policy; the Codex, OpenCode, and Copilot source paths below link to it.

| Tool | Dotfiles source | Installed location |
|------|-----------------|--------------------|
| Claude Code | `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Codex | `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| OpenCode | `config/opencode/AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| GitHub Copilot CLI | `config/copilot/copilot-instructions.md` | `~/.copilot/copilot-instructions.md` |

Run `bash install/agent-instructions.sh` to install just these links, or `./install.sh link` during normal setup. Existing files and differing symlinks are backed up before replacement. Re-running keeps correct links intact. Edits to a source file reach its installed location immediately; start a new tool session to reload instructions.

VS Code Copilot Agent Host uses the Copilot instruction file. For VS Code's Local agent, enable `chat.useClaudeMdFile` in user settings to load the Claude instructions. This is enabled on the current machine in both VS Code and VS Code Insiders; new machines need the setting enabled too. GitHub.com personal instructions are separate website settings and do not read local files.

### Shell (Zsh)

- **Prompt:** Starship with custom config (`config/starship/starship.toml`)
- **Plugins:** fzf-tab (via zfetch plugin manager)
- **Completions:** kubectl, limactl, 1Password CLI — all behind `command -v` guards
- **Node management:** fnm with auto-switch on `cd`
- **Navigation:** zoxide (aliased to `cd`)
- **Listing:** eza with icons and git status (`ll`, `l`)
- **FZF:** fd-backed file finder with custom color scheme
- **119 aliases** across navigation, git, docker, azure, AI tools, and more
- **30+ functions** including `extract`, `ghmerge`, `jwt` decode, tmux helpers
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

- **Global config:** `git/gitconfig.symlink` — generic, no accounts or signing required
- **Local overrides:** `~/.gitconfig-local` auto-linked from `~/Developer/clitools/` if present, otherwise stub created
- **Global ignore:** `git/gitignore_global.symlink`
- **Hooks:** pre-commit (jscs, jshint), post-merge templates
- **Account profiles (optional):** `git/profiles/<name>/` holds multi-account settings — host aliases, per-remote identities, and SSH auth/commit signing with keys served by the 1Password agent (looked up by item title via `agentkey.*` config, no key files on disk). Enable one with `DOTFILES_GIT_PROFILE=<name> ./install.sh git`; it links `~/.gitconfig-accounts` and `~/.ssh/config-accounts`. Without a profile, Git and SSH use plain defaults.

### Homebrew

`install/install_tools.sh` manages:

- **100+ formulas:** git, gh, neovim, go, rust, node, fzf, ripgrep, bat, eza, fd, starship, zoxide, tmux, lazygit, kubectl, k9s, helm, terraform, azure-cli, trivy, grype, trufflehog, pandoc, hugo, and more
- **70+ casks:** Ghostty, Claude, 1Password, Obsidian, Docker Desktop, Cursor, Figma, Discord, Postman, Azure Data Studio, OBS, and more
- **30+ taps:** 1password, azure, docker, hashicorp, oven-sh (bun), and more

### Claude Code

`claude/` directory symlinked to `~/.claude/` during install:

- **19 agents** (oh-my-claudecode orchestration)
- **15 custom commands**
- **Shared skills** moving to the separate skills repository and its `skillctl` manager
- **MCP server config** (`mcp.json`)
- **HUD display** and statusline customization

### Ponytail plugin

`claude/settings.base.json` declares the Ponytail marketplace and enables the plugin for both Claude backends. Run `./install.sh ponytail` to install Ponytail for Claude Code and Codex; `./install.sh all` also runs this step after installing the CLIs. The installer skips plugins that are already installed and checks that an existing Ponytail marketplace uses `DietrichGebert/ponytail`.

After installing in Codex, open `/hooks`, review Ponytail's two lifecycle hooks, and start a new chat. Restart the Codex desktop app to load the plugin.

### Microsoft Foundry OpenAI

Configure a separate Codex home with Azure CLI token authentication:

```bash
az login
./install.sh codex-foundry \
  --resource YOUR_FOUNDRY_OPENAI_RESOURCE \
  --model YOUR_OPENAI_DEPLOYMENT_NAME
```

The generated `~/.codex_foundry/config.toml` uses `bin/azure-openai-token`
as Codex's command-backed auth provider. It obtains short-lived Entra tokens
from the active Azure CLI session and does not configure an API key.

In T3 Code, add a second Codex provider with `CODEX_HOME` set to
`~/.codex_foundry` and the binary path set to `/opt/homebrew/bin/codex`.

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
| `install-caido-skills` | Install official Caido skills and dependencies into one project |

Install Caido skills only in projects that need them:

```bash
install-caido-skills /path/to/project
```

The command installs `caido/skills` under the project's `.agents/skills/`
directory and does not run as part of the default dotfiles installation.

### MacOS Defaults

`install/osx.sh` sets: Finder preferences, Dock behavior, keyboard repeat rates, terminal encoding, and UI tweaks.

### NvimTmux.App

`install/nvimtmux.sh` creates a custom macOS app that opens files in Neovim inside tmux. Registers file associations via `duti` for 20+ file types.

## Symlink Strategy

All `*.symlink` files are linked into `$HOME` with a leading dot (e.g., `zshrc.symlink` → `~/.zshrc`). Directories under `config/` are linked to `~/.config/<name>/`. Claude Code configs are linked to `~/.claude/`.

The canonical home for personal skills is [hacker1db/skills](https://github.com/hacker1db/skills), checked out locally at `~/Developer/skills/main`. Its `skillctl` CLI manages skill selection and installation for Codex, Claude Code, and GitHub Copilot CLI. The `bin/skillctl` launcher in this repo rebuilds the CLI from that checkout on every invocation, then runs it. Completion requests (`skillctl __complete …`, `skillctl completion …`) reuse the last build so Tab stays fast, and `zsh/completion.zsh` loads `skillctl completion zsh`. Go must be installed. Set `SKILLCTL_REPO_DIR` to use another checkout.

The `claude/skills/` tree in this repo is legacy content awaiting migration. The dotfiles linker no longer adopts skills into that tree or installs them from it. Existing global links remain in place until they are migrated through `skillctl`. A fresh dotfiles installation leaves skill setup to the skills repository. Its catalog needs to be ready before switching the global links; follow its README for CLI usage.

Re-running `./install.sh link` reconciles dotfiles symlinks, including vim compatibility links (`~/.vimrc`, `~/.vim`) and `~/.gitconfig-local`.

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
