# Dotfiles

Personal macOS development environment managed via modular installer, theme manager, and per‑repo Git identity overrides.

## Quick Start

```bash
git clone https://github.com/hacker1db/Dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh all
```

Re-run individual steps safely (idempotent):

```bash
./install.sh backup      # optional: backup existing dotfiles
./install.sh link        # create/update all symlinks (includes gitconfig-local logic)
./install.sh terminfo    # install terminfo entries
./install.sh homebrew    # install Homebrew + Brewfile packages
./install.sh shell       # shell related setup (zsh etc.)
./install.sh git         # git auth & credential helpers
./install.sh macos       # macOS defaults (review before running)
./install.sh extras      # extra tools/scripts
./install.sh theme       # theme manager (list/apply)
```

`./install.sh all` runs (in order): backup → link → terminfo → homebrew → shell → git → macos → extras → theme.

Non-interactive usage (CI / automation):

```bash
DOTFILES_NONINTERACTIVE=1 ./install.sh git
```

## Symlink Strategy

All `*.symlink` files inside the repo (up to max depth 3) are linked into `$HOME` with a leading dot. Example: `gitconfig.symlink` → `~/.gitconfig`. XDG style app configs under `config/` are linked to `~/.config/<name>/`.

Re-running `./install.sh link` reconciles:
- Home dotfile symlinks
- `~/.config` application directories
- Vim compatibility symlinks (`~/.vimrc`, `~/.vim`)
- `~/.zshrc` linking
- `~/.gitconfig-local` creation or updated symlink to `~/Developer/clitools/.gitconfig-local` (auto clone/update clitools if missing)

## Git Configuration

Global settings live in `git/gitconfig.symlink`. A local override file `~/.gitconfig-local` is included automatically if present (managed via `install/link.sh`). This lets you keep machine‑specific or private adjustments outside version control.

Behavior:
- If `~/Developer/clitools` exists, its `.gitconfig-local` is linked and used.
- If absent, an empty `~/.gitconfig-local` stub is created (edit as needed).
- Optional: add your own `includeIf` blocks to `git/gitconfig.symlink` for path-based custom settings.

Future enhancement: script generation of conditional includes for per-directory customization.

## Theme Manager

Invoke via:
```bash
./install.sh theme list      # list available themes
./install.sh theme apply Eldritch   # apply named theme
./install.sh theme current   # show current theme
./install.sh theme sync      # re-write integrations (tmux, ghostty, starship, nvim)
```
Applies:
- Tmux theme symlink (`tmux/themes/<theme>.conf` → `~/.tmux-theme.conf` or similar)
- Ghostty config line update for color scheme
- Starship prompt palette adjustment
- Neovim colorscheme loader (dynamic; prefers existing `eldritch` until refactor)

Add a shell alias/function (planned): `theme <name>` delegating to installer.

## Neovim Configuration

Location: `config/nvim/` using `lazy.nvim`. Key aspects:
- Completion: `blink.cmp` (not `nvim-cmp`)
- File explorer: `mini.files`
- Fuzzy picking: `mini.pick` for files/buffers (Telescope retained for some git ops)
- Formatting: `conform.nvim`
- Linting: `nvim-lint`
- Treesitter, LSP via `mason.nvim` + native client
- Git integrations: fugitive, gitsigns, neogit, octo
- UI helpers: snacks.nvim, lualine, etc.

Update / sync plugins headlessly:
```bash
nvim --headless "+Lazy! sync" +qa
```
Check health:
```bash
nvim +checkhealth
```

## Zsh Configuration

Primary file: `zsh/zshrc.symlink` (linked to `~/.zshrc`). It:
- Sets `EDITOR=nvim`
- Sources all subsidiary `.zsh` files (functions, aliases, completion guards)
- Adds `~/bin` and repo `bin/` to `PATH`
- Optionally sources `~/.localrc` for secrets or machine-specific overrides

Performance: avoid running expensive commands if binaries missing (guards already in place).

## Homebrew & Tools

`./install.sh homebrew` ensures Homebrew exists then installs packages from `install/brewfile`. (A wrapper script may later add fallback logic.)

## Non-Interactive Mode

Set `DOTFILES_NONINTERACTIVE=1` to skip prompts in `git.sh` and rely on existing global configurations.

## Customization Points

- Add/modify themes under `tmux/themes/` and Ghostty settings
- Extend Neovim plugins in `config/nvim/lua/plugins/` following existing spec pattern
- Edit `~/.gitconfig-local` for secondary identity values
- Introduce conditional `includeIf` blocks for path-based identity separation

## Maintenance

Re-run individual modules after changes (idempotent). Example after editing theme assets:
```bash
./install.sh theme sync
```
After adding new `*.symlink` file:
```bash
./install.sh link
```

## Roadmap (Planned Improvements)
- Conditional Git identity includes for specific project directories
- Dynamic Neovim colorscheme abstraction (remove hard-coded Eldritch usage)
- Starship palette modularization
- Brew wrapper with resilience & diff reporting
- Shell alias for theme switching

## Safety
No secrets stored in repo. 1Password SSH signing is configured for commit signing (`gpg.format=ssh`).

---
Feel free to fork and adapt. Suggestions: open issues or PRs.
