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
| Installer | `install/agent-profiles.zsh` (part of `./install.sh link`), shared with the Claude profiles |

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
~/Developer/ai-usage/main/scripts/install-proxy.sh          # build + LaunchAgent; resource from ANTHROPIC_FOUNDRY_RESOURCE
./install.sh link                                           # Claude profiles + ~/.codex-foundry
codex-foundry exec -s read-only --skip-git-repo-check "Reply with just: pong"
```

```zsh
zsh install/agent-profiles.zsh --check         # read-only audit of Claude and Codex profiles
zsh install/agent-profiles.zsh --skip-foundry  # leave Claude and Codex Foundry untouched
```

Without the proxy client key, the installer still creates `~/.codex-foundry` so the `xf` aliases
resolve, and prints a note; `codex-foundry` refuses to start until the key exists. `~/Developer/ai-usage/main/scripts/install-proxy.sh --check` reports the
binary, key, LaunchAgent, `/healthz`, and `/readyz` (which shows `az_login_required` when the Azure
CLI session has expired).

## Rules

- Don't run `codex login` inside the Foundry profile; the installer flags `~/.codex-foundry/auth.json`.
- Edit `codex/profiles/foundry/config.toml`, never the generated file or `~/.codex-foundry/config.toml`.
- Don't create `[model_providers.openai]`; it is a reserved built-in ID.
- Foundry sessions from before the split stay in `~/.codex/sessions`.

Claude Code profiles are documented separately in `claude/PROFILES.md`.

## Linux sandbox prerequisite

The Brewfile installs Bubblewrap on Linux. Codex uses the first `bwrap` on
`PATH`; the shell configuration exposes the Homebrew prefix in noninteractive
shells as well. Keep Bubblewrap at 0.12.0 or newer: Ubuntu's
`0.11.1-1ubuntu0.3` reverted the CVE-2026-87766 fix.

On Ubuntu with restricted unprivileged user namespaces, the distro AppArmor
profile attaches to `/usr/bin/bwrap`, not Homebrew's versioned executable. A
host administrator must load a separate copy of
`/etc/apparmor.d/bwrap-userns-restrict` with its attachment set to the resolved
Homebrew `bwrap` path and both profile names changed consistently to avoid
colliding with the distro profiles. Preserve all child capability restrictions.
Repeat that attachment check after a Homebrew upgrade changes the binary path.
Do not disable the global user-namespace restriction to work around a missing
attachment. If a GUI service does not inherit Homebrew on `PATH`, a host-managed
`/usr/local/bin/bwrap` symlink to the Homebrew executable makes it discoverable
without restarting unrelated services. Keep that link current after upgrades.

Verify a read-only command with `codex sandbox -c 'sandbox_mode="read-only"' --
/usr/bin/true`, then check that a write outside the workspace is still denied.
The RTK hook should rewrite a live Codex `git status --short` call to
`rtk git status --short`; changed hook definitions require renewed trust.

References: [Codex sandbox prerequisites](https://learn.chatgpt.com/docs/sandboxing#prerequisites),
[Ubuntu regression notice](https://ubuntu.com/security/notices/USN-8779-2),
[Bubblewrap advisory](https://github.com/containers/bubblewrap/security/advisories/GHSA-pxhw-h44j-8pfx).
