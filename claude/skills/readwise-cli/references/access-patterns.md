# Shared Readwise access router

Select by available capabilities and authentication, independent of model brand.

1. Prefer an authenticated plugin or MCP connection that supports the required operation. Discover its actual tool name and schema; namespaces differ by host.
2. Otherwise use an authenticated `readwise` CLI. Read `commands.md` and verify command help. For authentication, use interactive `readwise login`; do not request raw tokens in chat.
3. Use direct HTTP only when the other paths cannot perform the operation and an approved local integration supports secure credential injection. Inspect that integration before use. Keep credentials inside its process; never print, log, persist, or pass tokens in command arguments. If no secure integration is available, report the missing capability.

Select a route for each operation before mutating data. Do not repeat a successful operation through another route. After a timeout or partial failure, re-read current state, identify confirmed and unresolved IDs, and retry only unresolved work. If state cannot be established, report uncertainty and stop that operation.

Use Reader for saving sources unless the user asks for Highlights. Mutations require user authorization from the current task; read requests alone do not authorize moves, tags, or deletions. Paginate, preserve metadata, and distinguish confirmed success, failure, and unknown outcomes.

CLI syntax: `commands.md`. MCP syntax: `../../readwise-mcp/references/tools.md`. Active schemas take precedence over illustrative examples.
