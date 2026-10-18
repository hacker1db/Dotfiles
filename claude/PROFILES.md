# Claude Code profiles

Three isolated profiles, each with its own `CLAUDE_CONFIG_DIR`, login, settings, skills, and plugins.

| Profile | Config dir | Command | Aliases | Settings layers |
| --- | --- | --- | --- | --- |
| personal (default) | `~/.claude-personal` | `claude-personal` | `cc`, `ccc` | base + personal |
| work subscription | `~/.claude-subscription` | `claude-subscription` | `cw`, `cwc` | base + work |
| Foundry | `~/.claude-foundry` | `claude-foundry` | `cf`, `cfc` | base + work + foundry + resource + local autoMode |

`zsh/zshenv.symlink` exports `CLAUDE_CONFIG_DIR=~/.claude-personal`, so plain `claude` and `skillctl` use personal. The `bin/claude-*` wrappers override it for one launch and always run the native `~/.local/bin/claude`. GUI apps don't read `zshenv`; point them at a wrapper.

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
- `settings.foundry.json`: Foundry provider and deployment model defaults.

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
