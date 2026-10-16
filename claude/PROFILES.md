# Native Claude Code profiles

Profiles separate account configuration and history. For provider selection within the existing configuration directory, see [per-session launchers](../docs/claude-sessions.md).

Run the installer from the dotfiles root:

```sh
python3 install/claude-profiles.py --skip-foundry
```

The installer is also invoked by `install/link.sh`. It creates independent settings targets in `claude/.local/profiles/` and links individual settings files into private profile directories. Existing settings receive a private backup before replacement. Existing profile status lines and unrelated hooks are preserved. Plain `claude` and the existing convenience launchers keep their existing selection behavior.

## Everyday commands

```sh
CLAUDE_CONFIG_DIR="$HOME/.claude-foundry" claude
CLAUDE_CONFIG_DIR="$HOME/.claude-subscription" claude
CLAUDE_CONFIG_DIR="$HOME/.claude-personal" claude
```

Use the same directory with `claude --continue` or `claude --resume` to resume that profile's history. These commands require a shell without conflicting provider or authentication exports. The installer reports relevant inherited variable names without printing values. In an externally configured shell, unset those variables in a subshell before launching. Do not assume changing the configuration directory neutralizes inherited API keys, tokens, model overrides, or project settings.

## Local verification

```sh
python3 install/claude-profiles.py --skip-foundry --check
```

This check makes no configuration changes and requires no login. It verifies distinct settings targets, private permissions, first party provider selection, claude.ai login settings, work hook scope, hook file availability, and inherited provider conflicts. Exit status 2 identifies unresolved prerequisites or conflicts. The installation command also returns 2 when prerequisites remain missing. Passing fixture tests prove installer behavior; they do not prove live authentication or hook scanning.

Foundry setup is currently deferred. `--skip-foundry` leaves that profile untouched, including when a local Foundry input file exists. The full dotfiles installer still attempts all profiles and reports incomplete prerequisites without preventing unrelated links.

## Foundry prerequisite

Create a private local file at `~/.config/claude-code/foundry-profile.json`, with an `env` object containing the existing intended `ANTHROPIC_FOUNDRY_RESOURCE` or HTTPS `ANTHROPIC_FOUNDRY_BASE_URL`. Optional deployment names use `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, and `ANTHROPIC_DEFAULT_HAIKU_MODEL`. Set restrictive permissions on this file. No resource is automatically discovered. Credentials are not accepted in this file. Existing Azure authentication remains outside the generated configuration.

Rerun the installer after providing the configuration. It leaves Foundry uninstalled when no explicit endpoint is available and returns exit status 2 for missing prerequisites. The default deployment names come from `claude/settings.foundry.json`; verify those deployments exist before sending a request.

## Account onboarding and verification

1. Start subscription and personal separately with the direct commands. Log into the intended distinct claude.ai accounts. Confirm the browser account before authorizing. Use Chrome for computer assisted interaction. Do not copy tokens or credential files.
2. Inspect `/status`, close and relaunch each profile, and inspect `/status` again. Keep only nonsecret identity labels in verification records.
3. Authenticate Foundry using the existing Azure mechanism, launch its direct command, and confirm provider, resource, and model with `/status`.
4. Send one harmless prompt in each profile and check concurrent sessions for stable identities. Billing attribution remains unverified without billing evidence.
5. Review effective project and managed settings in each working repository. Personal sessions must not inherit work security hooks through project settings or plugins.

## Work hooks

`claude/settings.work.json` owns the commit security hook that runs GitGuardian. SonarQube hooks are managed separately and are not registered by this setup. Foundry and subscription receive these registrations. Personal excludes those registrations while preserving unrelated hooks. The legacy backend and session installers also load this fragment to preserve their existing work behavior.

The installer removes obsolete Sonar hook registrations while preserving unrelated hooks. No Sonar scripts are required. Plugin credentials and runtime state are not copied or shared between profiles.

## Tests and recovery

```sh
python3 install/tests/claude-profiles.test.py
bash install/tests/claude-session.test.sh
bash -n install/claude-backend.sh install/claude-session.sh install/link.sh
git diff --check
```

Restore an individual settings backup after removing its generated symlink if needed. Leave account directories and credentials intact. No logout, credential revocation, or deletion is required for rollback. Review the Git diff and restore only these implementation changes if rolling back the code. Git lifecycle remains manual.

## Current local setup

Verified on 2026-10-15: subscription and personal settings are installed with separate generated targets, profile directory mode 700, and settings file mode 600. Both report the first party provider and no logged in account. Concurrent status checks did not authenticate either profile. Default Claude settings, their symlink target, and the user managed status line remain unchanged. Generated settings are ignored by Git.

SonarQube hook registrations and the Sonar invocation in the commit hook were removed at user request. GitGuardian remains enabled for work profiles and excluded from personal. Account authentication and live service checks remain deferred. No plugin credentials or runtime state were shared.

Foundry onboarding and account login are deferred. Run the two everyday account commands when ready to authenticate. The original plan remains active for the deferred identity, request routing, and concurrent authenticated session checks.
