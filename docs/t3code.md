# T3 Code configuration

T3 reads `~/.t3/userdata/client-settings.json`, `~/.t3/userdata/settings.json`, and `~/.t3/userdata/keybindings.json`.

## Linked files

`config/t3code/client-settings.json` and `config/t3code/keybindings.json` are symlinked into `~/.t3/userdata/` by `install/t3-config.sh`. Changes made in T3 land directly in the checkout; review them with `git diff -- config/t3code` before committing. An existing regular file is moved to a timestamped `.backup-*` copy before the link is created. T3 may also write local state such as onboarding timestamps or favorites into `client-settings.json`.

`settings.json` is not linked. It holds provider credentials, binary paths, worktree directories, and per-machine provider entries. Do not commit it or the `~/.t3/userdata/secrets/` directory.

## Provider profiles during installation

`./install.sh link` and the integration phase of `./install.sh all` run `install/t3-config.sh` after the Claude profile installer and Codex configuration reconciliation. It links the UI files above and updates only `providerInstances` in `~/.t3/userdata/settings.json`. `link.sh` skips this step when `~/.t3` does not exist. Quit T3 and stop any standalone server using that directory before running installation.

| T3 instance | Profile source |
| --- | --- |
| `claudeAgent` (Claude personal) | `~/.claude-personal/settings.json` |
| `dotfiles-claude-subscription` | `~/.claude-subscription/settings.json` |
| `dotfiles-claude-foundry` | `~/.claude-foundry/settings.json` |
| `codex` | `~/.codex/config.toml` |
| `dotfiles-codex-home-foundry` | `~/.codex_foundry/config.toml` |

Claude entries come from the definitions under `claude/profiles/`. T3 runs the native `~/.local/bin/claude` with each profile's `homePath`, which T3 maps to `CLAUDE_CONFIG_DIR`. This selects the same settings/login context as the shell launchers without depending on interactive shell initialization. Codex entries use the discovered executable, explicit `homePath`, `setupMode: existing`, and no shadow home. They reuse the local CLI configuration and authentication instead of T3-managed authentication.

`config/t3code/profiles.json` declares additional Codex homes, including the Foundry placeholder. Paths beginning with `~/` expand at installation time, so no machine username is committed. Existing `~/.codex-*` and `~/.codex_*` homes with `config.toml` are also discovered. Duplicate normalized names fail before any write.

A missing settings file or executable creates a disabled T3 entry. `install.sh t3-config` and `--check` return status 2 for that; `link.sh` only warns, and skips provider setup entirely when `~/.t3` does not exist. After provisioning the profile, rerun setup to enable its entry. Readiness here checks files and executables; it does not verify login, model access, or API connectivity. Claude Foundry still needs its resource settings and Azure login. Codex Foundry needs a separately provisioned `~/.codex_foundry/config.toml`; this integration does not invent a resource, deployment name, or credential. The pre-existing Codex Foundry provisioner was found on the separate `feature/codex-foundry` branch, not in this branch's base `main`.

Codex named `*.config.toml` files are discovered as disabled placeholders. Codex CLI 0.164.0 rejects `--profile` for `app-server`, the transport used by this T3 build, even though [named profiles are supported for Codex runtime commands](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles). Use separate Codex homes for T3. The diagnostic explains this limitation instead of generating invalid launch arguments.

```sh
./install.sh t3-config --dry-run
./install.sh t3-config
./install.sh t3-config --check
```

Setup merges the managed driver, label, enabled state, binary/home paths and launch settings, while preserving credentials, other per-provider options, other providers, and the current default model selection. T3's own thread/model choices can override CLI model defaults; existing threads are not rewritten. Custom deployment models may still need to be selected in T3. Configured provider entries are refreshed on each install. Removing a profile definition does not delete its old T3 entry or history; remove retired entries in T3 explicitly.

Provider installer tests run with `python3 install/tests/t3-providers.test.py`. They exercise the `install.sh t3-config` entry point, UI file links and backups, five-profile mapping, incomplete placeholders, re-enabling, repeat install, local-state preservation, discovery, duplicate names, missing executables, and the integration-phase hook.
