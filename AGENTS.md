# AI Agent Guidelines

Personal macOS dotfiles: Zsh, Neovim, tmux, Ghostty, Git, Herdr, and AI coding tool profiles. [README.md](README.md) is the source of truth for installation and behavior; this file covers what agents need to work safely.

## Layout

```text
bin/          Scripts on PATH
config/       One directory per app, each linked to ~/.config/<name>
herdr/        Herdr config, linked file by file into ~/.config/herdr-app
git/          gitconfig, hook dispatchers (templates/hooks/) and hooks (hooks/)
zsh/          zshrc, zshenv, aliases, functions (functions/, functions.zsh, git.zsh)
install/      One script per install.sh step, plus lib.zsh and brewfile
global/       AGENTS.md: the global agent policy linked for Claude, Codex and Copilot
claude/       Claude Code profiles (see claude/PROFILES.md)
codex/        Codex profiles (see codex/PROFILES.md)
docs/         Integration guides
```

## Checkouts and Worktrees

`~/.dotfiles` is a bare repository with one worktree per branch; `~/.dotfiles/main` is the production checkout.

- `main` must always work. Never edit or commit in the `main` checkout.
- If the current worktree is on a feature branch, work there. Do not create another worktree or stack a branch for follow-up tasks; this overrides any global rule asking for a new worktree per task.
- Starting from `main`, create a worktree and branch with `wt switch -c <branch>`.
- Run every command from the worktree root with repo-relative paths. Paths under `~/.dotfiles/main` validate `main`, not your changes.
- Installed links (`~/.zshrc`, `~/.config/*`, `~/.git-templates`, and others) point at the selected checkout, `main` by default. Anything that writes through them, such as `Lazy sync` updating `lazy-lock.json` or `install.sh theme apply`, changes that checkout. Edit files in the worktree, never through `~/.config`.
- `./install.sh use` points the installed links at the current worktree for every terminal on the machine. Ask before running it, and switch back afterward with `dotfiles-use` from `~/.dotfiles/main`.

## Validation

```zsh
for f in install.sh install/*.zsh zsh/*.zsh zsh/*.symlink zsh/functions/* bin/tmux-reload-all; do zsh -n "$f" || print -u2 "syntax error: $f"; done
git diff --check
luacheck config/nvim
zsh install/agent-profiles.zsh --check
time zsh -i -c exit
```

- `agent-profiles.zsh --check` is a read-only audit of the installed Claude and Codex profiles.
- To rehearse linking without touching the real home: `HOME=$(mktemp -d) DOTFILES=$PWD zsh install/link.zsh`. It clones repositories and builds the plan CLI.
- Neovim has no automated tests. Check it interactively with `nvim +checkhealth`.
- `./install.sh {all|tools|link|...}` changes the live machine. Run it only when asked.
- Report startup timings only after measuring them.

## Conventions

### General

- Do not add code comments unless asked.
- Follow existing patterns, and check for existing functionality before adding more.
- Check `install/brewfile` and `install/tools.zsh` before assuming a tool is installed.
- Indentation follows `.editorconfig`: 4 spaces, including Lua and Zsh.

### Zsh

- Run shell commands with `/bin/zsh`, not Bash. Check syntax with `zsh -n`, never `bash -n`. Label shell code blocks `zsh`.
- Use `[[ ]]` for tests.
- Define functions in `zsh/functions/` (autoloaded, one per file) or `zsh/functions.zsh`.
- Guard external commands, completions, and evals with an existence check:

  ```zsh
  if command -v kubectl &> /dev/null; then
      source <(kubectl completion zsh)
  fi
  ```

### Neovim

- lazy.nvim imports `lua/plugins/` and its `extra`, `git`, `ui`, `lsp`, and `mini` subdirectories. Add one spec file per plugin in the matching subdirectory, returning a lazy.nvim spec table.
- Leader and local leader are both `;`. Keymaps live in `lua/core/keymaps.lua` or the plugin's `keys`. Grep for a mapping before adding one.
- Use double-quoted strings.
- Use blink.cmp, not nvim-cmp. Use the Snacks explorer, not nvim-tree. Use the Snacks picker for files, buffers, grep, and help, and keep the existing Telescope Git pickers.
- Prefer mini.nvim modules, and record new ones in `lua/plugins/mini/mini.md`.
- LSP servers are configured in `lua/plugins/lsp/lspconfig.lua`, formatting in conform.nvim, and linting in nvim-lint.

### Config Directories

New app config goes in `config/<app>/` in the worktree. `install.sh link` links it to `~/.config/<app>`, and skips any existing path that is not a symlink. Move or back up existing configuration at that path before linking.

### Commits

- Format: `type(scope): description`.
- Types: feat, fix, perf, refactor, docs, style, test, chore.
- Scopes name the area: install, zsh, nvim, tmux, git, ssh, herdr, ghostty, claude, codex, agents.

## Machine-Agnostic Dotfiles

The repository installs unchanged on many machines.

- Never put machine names, hostnames, local usernames, or absolute home paths (`/Users/<name>`) in tracked files or commit messages. Use `$HOME` or `~`.
- Never edit tracked config to fix a problem on one machine. Find the machine-local cause.
- Machine-specific settings belong in untracked files: `~/.gitconfig-local` or `~/.config/git/config` for Git, `git config --local` for one repository, `~/.localrc` for Zsh, and `~/.ssh/config` (machine-owned) for SSH.
- Each machine signs in to exactly one GitHub account. Code that needs it reads `git config github.user`; never hardcode GitHub account or organization names. Extra personal organizations are `github.org` values in `~/.gitconfig-local`.
- Before committing, search the diff for hostnames, usernames, and `/Users/` paths.

## Security

- Never commit, log, or expose secrets, API keys, or credentials. The GitGuardian pre-commit hook blocks them in personal repos, and CI runs TruffleHog.
- Never write SSH key files to disk, including public keys for `IdentityFile` pinning. Keys live only in a password manager and are served by its SSH agent. Fix key selection through the password manager, not through files in `~/.ssh`.
- Git signs with SSH keys from that agent. The signing key is set in `~/.gitconfig-local`.
- Unattended or service-account access belongs in the fleet-manager repository, not here.
- Zsh runs `compinit -C`, which skips the security check on completion directories.

## Boundaries

- Never modify the Claude Code status line: the `statusLine` block in `claude/settings.base.json`, `claude/statusline-command.sh`, or the generated `settings.json` in any Claude profile. The user manages it.
- Personal skills live in the [skills repository](https://github.com/hacker1db/skills), cloned to `$HOME/Developer/skills` and managed by `skillctl`. Read its README before changing skill behavior. Do not add skills here; `install/agent-profiles.zsh` runs `skillctl sync --global` for each Claude profile. Caido skills use the same skillctl workflow.
- `global/AGENTS.md` is the global agent policy for every repository. `claude/CLAUDE.md`, `codex/AGENTS.md`, and `copilot/copilot-instructions.md` are symlinks to it, so edit only `global/AGENTS.md`, and only when asked.
- Plan-manager integration is described in [docs/plan-manager.md](docs/plan-manager.md).
