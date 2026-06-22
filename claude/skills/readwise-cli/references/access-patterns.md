# Readwise Access Patterns

Use the lightest available access path:

1. Prefer installed Readwise plugin/MCP tools when they are available in the active client.
2. Otherwise use the `readwise` CLI.
3. Use direct HTTP API calls only when the CLI/plugin path cannot perform the needed operation.

When instructions mention MCP tool names, translate them to the equivalent CLI command if using the CLI. Example: `mcp__readwise__reader_list_documents` maps to `readwise reader-list-documents`.

Token handling:
- Never display, echo, log, or persist Readwise tokens.
- Prefer existing authenticated CLI/plugin sessions.
- If a direct API token is needed, retrieve it from 1Password only when the workflow explicitly calls for it, then unset it before finishing.

For full CLI command syntax, read `../SKILL.md`. For MCP tool syntax, read `../../readwise-mcp/SKILL.md`.
