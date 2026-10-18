# Dotfiles

Personal macOS development configuration for Zsh, Neovim, tmux, Ghostty, Git, and AI coding tools. Installation is split into scripts under `install/`; application settings live under `config/`.

## Installation

The repository is cloned bare with one worktree per branch, the same layout `bin/git-bare-clone` creates. That script is not on `PATH` yet, so clone by hand:

```sh
mkdir -p ~/.dotfiles && cd ~/.dotfiles
git clone --bare https://github.com/hacker1db/Dotfiles.git .bare
echo "gitdir: ./.bare" > .git
git --git-dir=.bare config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git --git-dir=.bare fetch origin
git --git-dir=.bare worktree add main main
git -C main branch --set-upstream-to=origin/main
cd main
./install.sh all
```

The installed links always point at `~/.dotfiles/main`. Branch worktrees (`wt switch -c <branch>`) land beside it in `~/.dotfiles/`.

Review the scripts before running a full installation: they install packages, change macOS preferences, configure applications, and prompt for logins as each step needs them. `all` runs `homebrew` right after `backup`; it installs the tools, then `install/verify.sh` checks for git, gh, Node.js 20+, pnpm, and Pandoc and runs `gh auth login` if GitHub is not logged in. If that check fails, `all` stops before linking. Run `bash install/verify.sh` on its own to recheck.

| Command | Purpose |
| --- | --- |
| `./install.sh backup` | Copy selected existing dotfiles into `~/dotfiles-backup` |
| `./install.sh link` | Link configuration, generate Claude settings/profiles, and bootstrap plan-manager |
| `./install.sh terminfo` | Install terminal capability entries |
| `./install.sh homebrew` | Run the explicit package lists and tool setup in `install/install_tools.sh` |
| `./install.sh node-tools` | Install pnpm global tools; run Readwise and Codex Security login setup |
| `./install.sh shell` | Configure Zsh |
| `./install.sh git` | Configure Git identity and optional account profiles |
| `./install.sh macos` | Apply macOS preferences |
| `./install.sh extras` | Install extra tools |
| `./install.sh nvimtmux` | Create NvimTmux.app and register file associations with `duti` |
| `./install.sh dotnet` / `./install.sh dotnet-tools` | Install .NET and global tools |
| `./install.sh theme list` | List theme candidates |

`all` runs backup, homebrew, link, terminfo, node-tools, shell, git, macos, extras, nvimtmux, dotnet, dotnet-tools, and theme, in that order. Individual steps can be rerun, but package updates, authentication, and generated settings are not no-op operations.

`DOTFILES_NONINTERACTIVE=1 ./install.sh git` suppresses the Git identity/profile prompts; it does not suppress every authentication prompt. The alternative Brewfile installation is `brew bundle --file=install/brewfile`; that catalog and the explicit lists in `install/install_tools.sh` are separate sources.

## Shell and terminal workflow

- Zsh loads `zsh/**/*.zsh`, autoloads `zsh/functions/`, and reads `~/.localrc` for local overrides.
- Starship supplies the prompt; zoxide provides `cd`; eza provides `l` and `ll`.
- fzf-tab uses zfetch; completion includes kubectl, limactl, 1Password, sesh, and skillctl. fnm selects Node versions when entering directories with Node project markers.
- `daily` opens a dated SecondBrain note, `yy` changes directory through Yazi, `ts` and Alt+s select sesh sessions, and `gh-rate-limit` inspects GitHub limits.
- Ghostty uses `config/ghostty/config`: JetBrains Mono italic at 14pt, 78% opacity, blur, linkarzu colors, and clipboard copy-on-select. The old WezTerm configuration has been removed.
- tmux lives in `config/tmux/tmux.conf`, uses Ctrl+a as its prefix, and includes vi copy mode, mouse support, undercurl colors, session persistence through resurrect/continuum, and Neovim pane navigation. Prefix+o opens sesh; prefix+g opens lazygit; prefix+G opens gh-dash; prefix+O opens OpenCode; prefix+u uses the fzf URL picker.

### Worktrunk and Git worktrees

`wt` shell integration is loaded from Zsh. User settings are in [config/worktrunk/config.toml](config/worktrunk/config.toml), linked at `~/.config/worktrunk/config.toml`. Worktrees use sibling directories named after sanitized branches; switching in tmux renames the window. Commit generation calls the configured `ocr` command, which must be available separately.

```sh
wt switch --create feature/my-change
wt pull-all
```

`wt pull-all` fetches every remote with pruning, then runs `git pull --ff-only --no-autostash` in each worktree **of the current repository** using that branch's configured upstream. Worktrees without a resolvable upstream, including detached worktrees, are skipped. A failed initial fetch stops the operation; individual pull failures are reported while remaining worktrees continue. Diverged branches require manual resolution. Local edits are not stashed; Git refuses updates that would overwrite them. This does not discover unrelated repositories or change remote URLs.

The `wt-pull-all` function in `zsh/functions.zsh` delegates to the same alias. Reload it with `source ~/.dotfiles/main/zsh/functions.zsh`. `cob` wraps `wt switch --create`; `git-bare-clone` supports cloning, `--init`, and `--fix` for a `.bare` repository with linked worktrees. Run `git-bare-clone --help` for its arguments. `gcc` invokes `git-clean-merged`, which can delete merged local **and remote** branches.

## Neovim

Configuration: `config/nvim/`. lazy.nvim imports the `extra`, `git`, `ui`, `lsp`, and `mini` plugin directories.

| Area | Current configuration |
| --- | --- |
| Completion | blink.cmp, LuaSnip, Copilot completion integration |
| LSP | mason.nvim, lspconfig, lspsaga; TypeScript tools, gopls, Lua, Python, Terraform, Docker, YAML, JSON, markdown-oxide, and harper-ls |
| Formatting/linting | conform.nvim and nvim-lint |
| Navigation/UI | Snacks explorer, picker, dashboard, notifier, indent, terminal, and zen; lualine, noice, which-key, trouble |
| Git | Fugitive, Gitsigns, Neogit, Octo; Telescope Git pickers and Snacks Git views |
| Editing | mini.ai, mini.comment, mini.icons, mini.pairs, mini.surround; Treesitter context, textobjects, and autotag |
| Markdown | Obsidian integration, render-markdown, heading capitalization, filetype-specific folds, `.svx` Markdown detection, and vault-backed LuaSnip templates |
| AI/testing/debugging | Copilot, CopilotChat, vim-test, and DAP configuration |
| Colors | Eldritch and custom diagnostic/heading highlights |

Space is the leader. Use `<leader>e` for the explorer, `<leader>ff` for files, `<leader>fr` for recent files, `<leader>/` for grep, `<leader>,` for buffers, and `<leader>sh` for help. `gd`/`gr` navigate LSP definitions/references. See `lua/core/keymaps.lua` and plugin `keys` tables for the complete mappings; some Git mappings are defined in both places.

The former nvim-cmp and nvim-tree configurations are removed. mini.files, mini.pick, and Avante are not configured. [Mini plugin notes](config/nvim/lua/plugins/mini/mini.md) describe the active modules. Standalone specs for mini.bracketed, mini.diff, and undotree remain directly under `lua/plugins/`, outside the imported directories; their presence and related keymaps do not establish that they load.

```sh
nvim +checkhealth
nvim --headless "+Lazy! sync" +qa
```

Plugin sync installs/updates plugins and can modify `lazy-lock.json`; it is not a read-only check. Obsidian and snippet configuration assumes a personal SecondBrain vault; adjust those paths for another machine. Legacy UltiSnips files remain under `vim/`.

## Git identities and hooks

`git/gitconfig.symlink` provides account-neutral defaults, `~/.gitconfig-local` overrides, `hunk pager`, Delta for interactive diffs, and fast-forward-only pulls. `ssh/config` includes local and optional account configuration.

```sh
DOTFILES_GIT_PROFILE=hacker1db ./install.sh git
```

The optional profile links `~/.gitconfig-accounts` and `~/.ssh/config-accounts`. It supplies remote-specific identities, SSH host aliases, and 1Password agent-backed authentication/signing through `bin/git-agent-key`, `bin/git-agent-ssh`, and `bin/git-agent-signing-key`. Keys are selected by configured agent item titles; private key files are not installed. Profile setup removes a local `user.signingkey` override. Review profile-specific account mappings before enabling it.

New repositories can inherit `git/templates/hooks/`. The dispatcher runs matching files in `git/hooks/` and propagates failures: JSCS/JSHint pre-commit checks, recent-branch tracking after checkout/merge, and a gitleaks secret scan of staged changes. The gitleaks hook blocks the commit when it finds a secret, and also when `gitleaks` is not installed. The hacker1db account profile sets `core.hooksPath` to `git/templates/hooks`, so the dispatcher runs for every repository. These Git hooks are separate from Claude's work-profile GitGuardian hook.

## CI and security scanning

`.github/workflows/ci.yml` runs the portable repository tests and shell, Zsh, and Lua lint checks on pushes to `main` and on pull requests. On pull requests, dependency review fails if a change adds a dependency with a known vulnerability of any severity. ShellCheck checks errors across repository shell scripts, omitting the bundled `bin/dotnet-install.sh` with existing findings. Luacheck ignores existing unused-variable and line-length warnings.

`.github/workflows/codeql.yml` runs CodeQL `security-extended` queries for GitHub Actions, JavaScript/TypeScript, and Python on pushes to `main`, on pull requests, and weekly. `.github/dependabot.yml` opens update pull requests for npm, NuGet, Docker, and pinned GitHub Actions. The workflow check is `python3 install/tests/ci-workflow.test.py`; it also requires every action to be pinned to a commit SHA.

## AI tools and shared instructions

| Tool | Source | Installed instruction file |
| --- | --- | --- |
| Claude Code | `claude/CLAUDE.md` | `~/.claude-{personal,subscription,foundry}/CLAUDE.md` |
| Codex | `codex/AGENTS.md` → `global/AGENTS.md` | `~/.codex/AGENTS.md` |
| OpenCode | `config/opencode/AGENTS.md` → `global/AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| Copilot CLI | `config/copilot/copilot-instructions.md` → `global/AGENTS.md` | `~/.copilot/copilot-instructions.md` |

Edit root `AGENTS.md` for repository guidance and `global/AGENTS.md` for shared policy. `bash install/agent-instructions.sh` installs just the instruction links with backups. Start a new tool session to reload them.

Claude installation links instructions, agents, commands, output styles, and the statusline script into each profile directory, and generates each profile's settings from layered fragments. MCP configuration is linked to `~/.mcp.json`.

- [Claude profiles](claude/PROFILES.md): `cc` (personal, the default), `cw` (work subscription), and `cf` (Foundry) each use their own `CLAUDE_CONFIG_DIR` with separate login, settings, skills, and plugins. `./install.sh link` generates and installs all three.
- Claude agents and commands cover reviews, GitHub/Azure DevOps, security, notes, reading, and writing workflows. gitleaks runs as a Git hook, not a Claude hook.
- OpenCode includes agent/command definitions, TUI settings, and a Supacode presence plugin that emits activity only inside Supacode surfaces.

### Personal skills

Personal skill sources live in [hacker1db/skills](https://github.com/hacker1db/skills). `bin/skillctl` resolves a normal checkout at `~/Developer/skills` or its `main/` worktree, rebuilds the Go CLI for normal invocations, and reuses the last build for completion. Set `SKILLCTL_REPO_DIR` for another checkout. Follow that repository's README for selections and installation.

Dotfiles holds no personal skills; they come from the skills repository through skillctl, which the profile installer runs for each Claude profile. The OpenCode Supacode skill and project-only `bin/install-caido-skills` remain separate.

```sh
install-caido-skills /path/to/project
```

### Plan-manager integration

[Plan-manager setup and troubleshooting](docs/plan-manager.md) documents the separate application checkout, `~/.local/bin/plan`, LaunchAgent, and Codex writable-root reconciliation. Dotfiles policy uses `~/notes/SecondBrain/4.Resources/plans` as the canonical library and `http://plans.localhost:4173/` as its local dashboard. The linker builds the application and checks its service; application source and plan data are not stored here. Publishing requires an explicit request.

## Symlinks and themes

`*.symlink` sources map into `$HOME` with a leading dot; `config/*` maps into `~/.config/`. The general loops skip existing targets. Managed instruction links and selected integrations have their own replacement/backup behavior. In particular, a discovered clitools Git config replaces `~/.gitconfig-local`; preserve local edits before relinking. `link` may clone/update clitools and plan-manager, build dependencies, and start the dashboard service.

```sh
./install.sh theme list
./install.sh theme apply eldritch
./install.sh theme current
./install.sh theme sync
```

The theme script writes Neovim, Starship, Ghostty, and tmux settings. Candidate names come from the terminal/tmux theme files; a listed name does not guarantee a matching theme for every application. These operations can modify tracked configuration.

## Validation

The installer fixture tests use temporary homes/repositories rather than changing live profiles or loading a LaunchAgent:

```sh
bash install/tests/claude-profiles.test.sh
python3 install/tests/ci-workflow.test.py
bash install/tests/plan-manager-bootstrap.test.sh
node install/tests/plan-manager-harness-contracts.test.mjs
zsh -n zsh/zshrc.symlink
zsh -n zsh/functions.zsh
git diff --check
```

These checks do not prove a complete fresh-machine install, live provider authentication, or interactive Neovim/tmux behavior. No credentials should be committed; use local configuration and the configured credential providers.
