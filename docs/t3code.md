# T3 Code configuration

Portable preferences are checked in at `config/t3code/preferences.json`. The snapshot was captured from T3 Code nightly `0.1.3-nightly.20261024.3643`. It includes interface/composer preferences, 82 keybindings, portable server defaults, the Codex default model and its reasoning/service-tier options, and Antigravity's enabled state and personal OAuth authentication mode.

T3 reads `~/.t3/userdata/client-settings.json`, `~/.t3/userdata/settings.json`, and `~/.t3/userdata/keybindings.json`. Provider definitions are under `providerInstances` in `settings.json`; `defaultModelSelection` chooses the default provider/model. T3 can store inline API keys there as well as secrets under `~/.t3/userdata/secrets/`. Do not commit that directory or copy these live settings wholesale.

## Provider profiles during installation

`./install.sh link` and the integration phase of `./install.sh all` run `install/t3-config.sh` after the Claude profile installer and Codex configuration reconciliation. This updates only `providerInstances` in `~/.t3/userdata/settings.json`. Quit T3 and stop any standalone server using that directory before running installation.

| T3 instance | Profile source |
| --- | --- |
| `claudeAgent` (Claude personal) | `~/.claude-personal/settings.json` |
| `dotfiles-claude-subscription` | `~/.claude-subscription/settings.json` |
| `dotfiles-claude-foundry` | `~/.claude-foundry/settings.json` |
| `codex` | `~/.codex/config.toml` |
| `dotfiles-codex-home-foundry` | `~/.codex_foundry/config.toml` |

Claude entries come from the definitions under `claude/profiles/`. T3 runs the native `~/.local/bin/claude` with each profile's `homePath`, which T3 maps to `CLAUDE_CONFIG_DIR`. This selects the same settings/login context as the shell launchers without depending on interactive shell initialization. Codex entries use the discovered executable, explicit `homePath`, `setupMode: existing`, and no shadow home. They reuse the local CLI configuration and authentication instead of T3-managed authentication.

`config/t3code/profiles.json` declares additional Codex homes, including the Foundry placeholder. Paths beginning with `~/` expand at installation time, so no machine username is committed. Existing `~/.codex-*` and `~/.codex_*` homes with `config.toml` are also discovered. Duplicate normalized names fail before any write.

A missing settings file or executable creates a disabled T3 entry and returns status 2. The full installer reports incomplete setup rather than success. After provisioning the profile, rerun setup to enable its entry. Readiness here checks files and executables; it does not verify login, model access, or API connectivity. Claude Foundry still needs its resource settings and Azure login. Codex Foundry needs a separately provisioned `~/.codex_foundry/config.toml`; this integration does not invent a resource, deployment name, or credential. The pre-existing Codex Foundry provisioner was found on the separate `feature/codex-foundry` branch, not in this branch's base `main`.

Codex named `*.config.toml` files are discovered as disabled placeholders. Codex CLI 0.164.0 rejects `--profile` for `app-server`, the transport used by this T3 build, even though [named profiles are supported for Codex runtime commands](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles). Use separate Codex homes for T3. The diagnostic explains this limitation instead of generating invalid launch arguments.

```sh
./install.sh t3-config --dry-run
./install.sh t3-config
./install.sh t3-config --check
```

Setup merges the managed driver, label, enabled state, binary/home paths and launch settings, while preserving credentials, other per-provider options, other providers, and the current default model selection. T3's own thread/model choices can override CLI model defaults; existing threads are not rewritten. Custom deployment models may still need to be selected in T3. Configured provider entries are refreshed on each install. Removing a profile definition does not delete its old T3 entry or history; remove retired entries in T3 explicitly.

## Capture changes

After changing settings in T3, quit the app and export from the dotfiles checkout you intend to commit:

```sh
python3 bin/t3-config export
git diff -- config/t3code/preferences.json
```

Export uses an explicit field allowlist. It omits API keys, tokens, account identifiers, browser profiles, connection catalogs, worktree paths, provider binary paths, project overrides, custom model definitions, and runtime/history databases. Unknown future settings are omitted until reviewed. Only the built-in `codex`, `claudeAgent`, and `antigravity` instance names are eligible; account-specific instances and their default model selections remain local. This is a portable preference snapshot, not a full T3 backup. Review the diff before committing, especially manually entered string values.

## Restore preferences

Quit T3 and stop any standalone T3 server using the same userdata directory before applying. From the checkout:

```sh
python3 bin/t3-config apply --dry-run
python3 bin/t3-config apply
```

The command merges managed fields into existing settings, preserving credentials and unlisted local fields. It replaces portable keybindings with the captured list while retaining local `script.*` bindings. T3 can add newly introduced default shortcuts on startup. Existing provider entries with a different driver are rejected. Each changed file gets a private, same-directory `.backup-*` copy before atomic replacement; unchanged files produce no backup. Restore an individual file from its backup with T3 stopped. Backups may contain credentials and must stay outside Git.

Applying the UI/keybinding snapshot remains explicit; installation automatically reconciles provider profiles only. Its `~/.config/t3code` link only exposes the snapshot; T3 itself does not read that location. Provider login remains a per-machine operation. Restart T3 after applying and sign in to the configured providers as needed. Neither export nor apply installs provider executables or changes their own CLI configuration.

`--userdata PATH` selects a different T3 data directory; `--config PATH` selects a different snapshot. The script requires Python 3 and no third-party packages. Fixture checks run with `python3 install/tests/t3-config.test.py`; they cover credential exclusion, local-state preservation, private backups, repeat apply, dry runs, invalid snapshots, and fresh-machine setup.

Provider installer tests run with `python3 install/tests/t3-providers.test.py`. They exercise the `install.sh t3-config` entry point, five-profile mapping, incomplete placeholders, re-enabling, repeat install, local-state preservation, discovery, duplicate names, missing executables, and the integration-phase hook.
