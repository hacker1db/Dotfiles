# Codex CLI profiles

Two profiles share one `CODEX_HOME` (`~/.codex`), so MCP servers, plugins, trusted projects,
writable roots, `AGENTS.md`, and hooks apply to both. The Foundry profile is an overlay file that
Codex loads only with `-p foundry`; plain `codex` never reads it.

| Profile | Command | Aliases | Auth | Models |
| --- | --- | --- | --- | --- |
| personal (default) | `codex` | `xp`, `xpc` | ChatGPT login in `~/.codex/auth.json` | from `~/.codex/config.toml` |
| Foundry | `codex-foundry` (`codex -p foundry`) | `xf`, `xfc` | Entra ID through `foundry-entra-proxy` | `gpt-6.1-sol` (default), `gpt-6-luna`, `gpt-6-astra` |

The `*c` aliases resume the most recent session (`resume --last`). Sessions from both profiles land
in `~/.codex/sessions`; resume a Foundry session with `xfc` or `codex-foundry resume`, not `xpc`.
Pick another deployment per run with `xf -m gpt-6-luna`.

## How the Foundry profile works

```
codex-foundry ─► codex -p foundry ─► foundry-entra-proxy 127.0.0.1:8787 ─► Foundry /openai/v1
   (reads client key)    (overlay picks provider)    (az Entra token, allowlist, usage log)
```

- `codex/foundry.config.toml` defines the `foundry` provider (`base_url` is the proxy, `env_key` is
  `FOUNDRY_PROXY_KEY`) and is linked to `~/.codex/foundry.config.toml` by `install/link.zsh`. It
  holds no secrets.
- `bin/codex-foundry` checks the overlay, the client key
  (`~/.config/foundry-entra-proxy/client.key`), and the proxy's `/healthz`, then runs
  `codex -p foundry` with `FOUNDRY_PROXY_KEY` set for that process only.
- The proxy turns your `az login` session into an Entra bearer token. It never sees the ChatGPT
  login, and the personal profile never talks to the proxy.
- Every Foundry request is logged with model, client, and token counts in
  `~/Library/Logs/foundry-entra-proxy/proxy.log`.

## Setup

```zsh
az login                                                    # Entra session for the proxy
~/Developer/clitools/foundry-entra-proxy/install.sh         # build + LaunchAgent; resource from ANTHROPIC_FOUNDRY_RESOURCE
zsh install/link.zsh                                        # links the overlay (or ./install.sh link)
codex-foundry exec -s read-only --skip-git-repo-check "Reply with just: pong"
```

`~/Developer/clitools/foundry-entra-proxy/install.sh --check` reports the binary, key, LaunchAgent,
`/healthz`, and `/readyz` (which shows `az_login_required` when the Azure CLI session has expired).

## Rules

- Don't add `profile = "foundry"` or a `[profiles.foundry]` table to `~/.codex/config.toml`. Codex
  0.166 refuses to start with `-p foundry` while either exists; `install/link.zsh` warns about it.
- Don't create `[model_providers.openai]`; it is a reserved built-in ID.
- New overlays go in `codex/<name>.config.toml`; `install/link.zsh` links every `*.config.toml` it
  finds there.

Claude Code profiles are documented separately in `claude/PROFILES.md`.
