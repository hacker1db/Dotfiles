# T3 Code configuration

Portable preferences are checked in at `config/t3code/preferences.json`. The snapshot was captured from T3 Code nightly `0.1.3-nightly.20261024.3643`. It includes interface/composer preferences, 82 keybindings, portable server defaults, the Codex default model and its reasoning/service-tier options, and Antigravity's enabled state and personal OAuth authentication mode.

T3 reads `~/.t3/userdata/client-settings.json`, `~/.t3/userdata/settings.json`, and `~/.t3/userdata/keybindings.json`. Provider definitions are under `providerInstances` in `settings.json`; `defaultModelSelection` chooses the default provider/model. T3 can store inline API keys there as well as secrets under `~/.t3/userdata/secrets/`. Do not commit that directory or copy these live settings wholesale.

## Capture changes

After changing settings in T3, quit the app and export from the dotfiles checkout you intend to commit:

```sh
python3 bin/t3-config export
git diff -- config/t3code/preferences.json
```

Export uses an explicit field allowlist. It omits API keys, tokens, account identifiers, browser profiles, connection catalogs, worktree paths, provider binary paths, project overrides, custom model definitions, and runtime/history databases. Unknown future settings are omitted until reviewed. Only the built-in `codex`, `claude-code`, and `antigravity` instance names are eligible; account-specific instances and their default model selections remain local. This is a portable preference snapshot, not a full T3 backup. Review the diff before committing, especially manually entered string values.

## Restore preferences

Quit T3 and stop any standalone T3 server using the same userdata directory before applying. From the checkout:

```sh
python3 bin/t3-config apply --dry-run
python3 bin/t3-config apply
```

The command merges managed fields into existing settings, preserving credentials and unlisted local fields. It replaces portable keybindings with the captured list while retaining local `script.*` bindings. T3 can add newly introduced default shortcuts on startup. Existing provider entries with a different driver are rejected. Each changed file gets a private, same-directory `.backup-*` copy before atomic replacement; unchanged files produce no backup. Restore an individual file from its backup with T3 stopped. Backups may contain credentials and must stay outside Git.

Apply is explicit: the general dotfiles linker does not apply T3 preferences. Its `~/.config/t3code` link only exposes the snapshot; T3 itself does not read that location. Provider login remains a per-machine operation. Restart T3 after applying and sign in to the configured providers as needed. Neither export nor apply installs provider executables or changes their own CLI configuration.

`--userdata PATH` selects a different T3 data directory; `--config PATH` selects a different snapshot. The script requires Python 3 and no third-party packages. Fixture checks run with `python3 install/tests/t3-config.test.py`; they cover credential exclusion, local-state preservation, private backups, repeat apply, dry runs, invalid snapshots, and fresh-machine setup.
