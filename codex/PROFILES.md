# Codex CLI profiles

Like the Claude Code profiles, each Codex profile has its own home directory (`CODEX_HOME`) with a
separate login, config, sessions, and skills. The Foundry profile never sees the personal ChatGPT
login, plugins, or connectors, and nothing machine- or work-specific is committed.

| Profile | Home | Command | Aliases | Auth | Models |
| --- | --- | --- | --- | --- | --- |
| personal (default) | `~/.codex` | `codex` | `xp`, `xpc` | ChatGPT login in `~/.codex/auth.json` | from `~/.codex/config.toml` |
| Foundry | `~/.codex-foundry` | `codex-foundry` | `xf`, `xfc` | Entra ID through `foundry-entra-proxy` | `gpt-6.1-sol` (default), `gpt-6-luna`, `gpt-6-astra` |

The `*c` aliases resume the most recent session (`resume --last`) in that profile's home. Pick
another deployment per run with `xf -m gpt-6-luna`.

## Files

| Item | Path |
| --- | --- |
| Foundry template (committed) | `codex/profiles/foundry/config.toml` |
| Generated config (ignored by Git, mode 600) | `codex/.local/profiles/foundry.toml` |
| Linked into `~/.codex-foundry` | `config.toml` → generated config, `AGENTS.md` → `global/AGENTS.md`, `hooks.json` → `codex/hooks.json` |
| Skills | `~/.codex-foundry/skills`, filled by `CODEX_HOME=~/.codex-foundry skillctl sync --global` |
| Launcher | `bin/codex-foundry` |
| Installer | `install/agent-profiles.zsh` (`./install.sh agent-profiles`), shared with the Claude profiles |

The generated config is the template plus the plan library under
`sandbox_workspace_write.writable_roots`, built from `$HOME` at install time. Codex writes hook
trust and project trust back into `config.toml`; that lands below the marker line in the generated
file, which the installer keeps when it regenerates the managed part above it.

## GUI apps (T3 Code)

Point a GUI Codex instance at the launcher, with `~/.codex-foundry` as its home and no shadow home;
the shadow home only exists to keep a separate `auth.json`, and Foundry has no login. When
`~/.t3/userdata/settings.json` exists, the installer rewrites any T3 Code Codex instance whose home
or shadow home mentions `.codex-foundry` to exactly that (`--check` reports drift). Restart T3 Code
afterwards. The launcher adds `/opt/homebrew/bin` and `~/.local/bin` to `PATH` for apps that don't
load the shell.

## How the Foundry profile works

```text
codex-foundry ─► codex (CODEX_HOME=~/.codex-foundry) ─► foundry-entra-proxy 127.0.0.1:8787 ─► Foundry /openai/v1
 (reads client key)        (config picks provider)        (az Entra token, allowlist, usage log)
```

- `bin/codex-foundry` checks the config, the client key
  (`~/.config/foundry-entra-proxy/client.key`), and the proxy's `/healthz`, then runs `codex` with
  `CODEX_HOME` and `FOUNDRY_PROXY_KEY` set for that process only. `CODEX_FOUNDRY_HOME`,
  `FOUNDRY_PROXY_KEY_FILE`, and `FOUNDRY_PROXY_URL` override the defaults.
- The proxy turns your `az login` session into an Entra bearer token. It never sees the ChatGPT
  login, and the personal profile never talks to the proxy.
- Every Foundry request is logged with model, client, and token counts in
  `~/Library/Logs/foundry-entra-proxy/proxy.log`.

## Setup

```zsh
az login                                                    # Entra session for the proxy
~/Developer/clitools/foundry-entra-proxy/install.sh         # build + LaunchAgent; resource from ANTHROPIC_FOUNDRY_RESOURCE
./install.sh agent-profiles                                 # Claude profiles + ~/.codex-foundry
codex-foundry exec -s read-only --skip-git-repo-check "Reply with just: pong"
```

```zsh
zsh install/agent-profiles.zsh --check         # read-only audit of Claude and Codex profiles
zsh install/agent-profiles.zsh --skip-foundry  # leave Claude and Codex Foundry untouched
```

Without the proxy client key, Foundry is skipped; on a machine with `~/OneDrive*` that is reported
as incomplete (exit 2). `~/Developer/clitools/foundry-entra-proxy/install.sh --check` reports the
binary, key, LaunchAgent, `/healthz`, and `/readyz` (which shows `az_login_required` when the Azure
CLI session has expired).

## Rules

- Don't run `codex login` inside the Foundry profile; the installer flags `~/.codex-foundry/auth.json`.
- Edit `codex/profiles/foundry/config.toml`, never the generated file or `~/.codex-foundry/config.toml`.
- Don't create `[model_providers.openai]`; it is a reserved built-in ID.
- Foundry sessions from before the split stay in `~/.codex/sessions`.

Claude Code profiles are documented separately in `claude/PROFILES.md`.
