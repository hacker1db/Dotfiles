## Why

The current Claude backend installer rewrites a shared generated settings file and global symlink. Provider selection must instead belong to each launched session so subscription and Microsoft Foundry sessions can run concurrently.

## What Changes

- Add `claude-subscription` and `claude-foundry` session launchers using invocation-specific settings, preserving shared customization and the user-managed statusLine without writing global settings.
- Let Foundry endpoints and deployment names be selected explicitly; discover resources only when there is exactly one eligible match.
- Authenticate Claude Foundry using the Azure credential chain and the user’s Azure CLI login.
- Preserve existing launch arguments, subscription credentials, global defaults, and the legacy installer.
- Document use in concurrent terminal or tmux sessions. Initial scope is CLI sessions; desktop integration requires separate verification.

## Impact

- Affected specs: ai-provider-sessions
- Affected code: new session launchers in bin/, Claude settings fragments, shell integration if needed, documentation and focused tests
- Existing uncommitted plan-manager work remains untouched.

## Approval

Approved by the user; implemented for Claude Code CLI sessions.
