# Claude Code profiles

Three isolated profiles, each with its own `CLAUDE_CONFIG_DIR`, login, settings, skills, and plugins.

| Profile | Config dir | Command | Aliases | Settings layers |
| --- | --- | --- | --- | --- |
| personal (default) | `~/.claude-personal` | `claude-personal` | `cc`, `ccc` | base + personal |
| work subscription | `~/.claude-subscription` | `claude-subscription` | `cw`, `cwc` | base + work |
| Foundry | `~/.claude-foundry` | `claude-foundry` | `cf`, `cfc` | base + work + foundry + resource + local autoMode |

`zsh/zshenv.symlink` exports `CLAUDE_CONFIG_DIR=~/.claude-personal`, so plain `claude` and `skillctl` use personal. The `bin/claude-*` wrappers override it for one launch and always run the native `~/.local/bin/claude`. GUI apps don't read `zshenv`; point them at a wrapper.

## Where everything lives

Use these absolute paths from GUI apps and other tools (such as T3 Code) that don't load the shell.

| What | Path |
| --- | --- |
| Claude Code binary (native, auto-updating) | `~/.local/bin/claude` |
| Personal launcher | `~/.dotfiles/bin/claude-personal` |
| Work subscription launcher | `~/.dotfiles/bin/claude-subscription` |
| Foundry launcher | `~/.dotfiles/bin/claude-foundry` |
| Profile config dirs | `~/.claude-personal`, `~/.claude-subscription`, `~/.claude-foundry` |
| Generated settings (ignored by Git, mode 600) | `~/.dotfiles/claude/.local/profiles/{personal,subscription,foundry}.json` |
| Settings layers (committed) | `~/.dotfiles/claude/settings.{base,personal,work,foundry}.json` |
| Foundry resource | `ANTHROPIC_FOUNDRY_RESOURCE` in `~/.localrc` → `~/OneDrive*/Personal/.localrc` |
| Local autoMode input | `~/.config/claude-code/automode.json` (falls back to `foundry-automode.json`) |
| MCP servers (all profiles) | `~/.mcp.json` → `~/.dotfiles/claude/mcp.json` |
| Installer and test | `~/.dotfiles/install/claude-profiles.sh`, `install/tests/claude-profiles.test.sh` |

Each profile dir contains:

- `settings.json`: a symlink to that profile's generated settings
- symlinks to the dotfiles copies of `CLAUDE.md`, `agents/`, `commands/`, `output-styles/` and `statusline-command.sh`
- `skills/`: a real dir of links managed by skillctl
- `plugins/`: plugins installed for that profile only
- login credentials and history, which Claude writes itself

There are two ways for a tool to select a profile:

1. Run a launcher as the Claude binary. This is the simplest option and needs no environment setup.
2. Run `~/.local/bin/claude` with `CLAUDE_CONFIG_DIR` set to the profile dir.

The Foundry profile also needs a working `az login`. Its resource and model come from its settings file, not from the environment.

`~/.claude` is the legacy config dir. Dotfiles no longer links anything into it. The only managed links left there are skillctl's in `~/.claude/skills`, which skillctl keeps and never relinks.

## Install

`./install.sh link` runs `install/claude-profiles.sh`, which:

- links `~/.localrc` to `~/OneDrive*/Personal/.localrc`, and fails if there isn't exactly one OneDrive dir or the file hasn't synced
- merges the layers with jq into ignored `claude/.local/profiles/<profile>.json` (mode 600), linked as `~/.claude-<profile>/settings.json` (dir mode 700), and backs up an unmanaged `settings.json` once
- links `CLAUDE.md`, `agents/`, `commands/`, `output-styles/`, `statusline-command.sh` into each profile
- creates a real `skills/` dir and fills it with `CLAUDE_CONFIG_DIR=<dir> skillctl sync --global`
- adds the declared marketplaces and installs the declared plugins per profile

Foundry reads `ANTHROPIC_FOUNDRY_RESOURCE` from the environment, or from `~/.localrc`. Rerun the installer after changing it. `~/.config/claude-code/automode.json` (or `foundry-automode.json`) contributes only `autoMode.environment`. Layers that contain `apiKeyHelper` or API keys or tokens are rejected.

```sh
install/claude-profiles.sh --check         # read-only audit
install/claude-profiles.sh --skip-foundry  # leave Foundry untouched
```

Exit codes: 0 means ready, 1 means a hard error (credentials, `.localrc` layout, symlinked dirs), and 2 means incomplete (no Foundry resource, stale state, or inherited `ANTHROPIC_*`/`CLAUDE_CODE_USE_*` variables, which are reported by name only).

## Layers

- `settings.base.json`: shared plugins, `enabledMcpjsonServers` (github, playwright from `~/.mcp.json`), `permissions.defaultMode: auto`, deny rules, statusline.
- `settings.personal.json`: personal-only plugins (vercel, todoist).
- `settings.work.json`: work-only settings for subscription and Foundry. GitGuardian runs as a git hook (`core.hooksPath`), not a Claude hook.
- `settings.foundry.json`: Foundry provider and deployment model defaults. Uses `opus` (the configured Opus 4.8 deployment) for auto mode compatibility; `opusplan` would select the unsupported Sonnet 4.6 deployment during execution.

The generated files also pin the provider: Foundry sets `CLAUDE_CODE_USE_FOUNDRY=1`, while personal and subscription set it to `0` and add `forceLoginMethod: claudeai`. All three set Bedrock and Vertex to `0`.

## First use

1. `cc` and `cw`: log in to the personal and the work claude.ai account. Then run `/status`, quit, relaunch, and check that `/status` shows the same account.
2. `cf`: needs `az login`. In `/status`, confirm the provider is Foundry and the resource is correct. Confirm auto mode works.
3. Open all three at once and check that each `/status` stays distinct.

Claude Console (API-key) logins are stored outside `CLAUDE_CONFIG_DIR`, so they are not isolated. Profiles isolate config and auth, not the filesystem, so use separate worktrees when concurrent sessions edit one repo.

## Tests

```sh
bash install/tests/claude-profiles.test.sh
```

## Rollback

Revert the dotfiles commits, rerun `./install.sh link`, and launch plain `claude` with `CLAUDE_CONFIG_DIR` unset. `~/.claude` stays intact until the profiles are verified.
