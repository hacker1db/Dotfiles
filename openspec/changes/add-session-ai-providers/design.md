## Context

`install/claude-backend.sh` merges base settings, a backend fragment, and local autoMode settings into `claude/.local/settings.generated.json`, then links the result to the global Claude settings path. Every switch therefore affects a shared file.

Claude supports `--settings` and `--setting-sources`.

## Decisions

- Use explicit launch commands for each provider. A session chooses its provider once at launch; another session cannot change it by switching global configuration.
- Claude launchers must avoid inheriting conflicting provider variables and global Foundry model defaults. Preserve normal customizations, local autoMode configuration, and statusLine while supplying a complete provider selection with higher precedence. Use CLI `--settings` overrides with empty credential/model variables to mask conflicting lower-level values; user/project settings continue loading normally. Leave statusLine out of the override. Organization-managed settings retain precedence.
- Use Claude’s native Azure credential chain with the user’s `az login` session. Clear inherited API keys and bearer tokens so Foundry uses Azure CLI credentials without storing tokens in configuration or passing them in command-line arguments.
- Explicit resource/endpoint selection wins. Ambiguous discovery fails with an actionable message rather than choosing the first account.

## Validation

Use stubbed CLI commands to verify concurrent provider isolation, argument forwarding, inherited credential cleanup, resource ambiguity, Azure credential-chain selection, failure propagation, and unchanged global settings and marker files. Live discovery was attempted without exposing tokens or modifying Azure resources; Azure rejected the cached login with AADSTS9002313 and requested reauthentication. Live inference remains unverified.

## Sources

- https://code.claude.com/docs/en/azure-ai-foundry

## Implementation

`bin/claude-subscription` and `bin/claude-foundry` invoke `install/claude-session.sh`. Each session gets a private temporary directory cleaned up on exit. Session settings contain the backend fragment and optional local autoMode overrides; credentials and provider selection are enforced after merging. Global settings and the legacy installer remain unchanged. Foundry deployment variables supplied in the launch environment override fragment defaults. Subscription sessions use the model from the live base settings.
