# Plan CLI Reference

Executable: `plan` (linked at `~/.local/bin/plan` from the application worktree)

All machine-readable commands accept `--json`. JSON mode writes only the response envelope to stdout; diagnostics go to stderr.

## JSON response envelope

```json
{
  "version": 1,
  "id": "<stable-nanoid>",
  "title": "<string>",
  "path": "<absolute-path>",
  "url": "http://plans.localhost:4173/plans/<id>",
  "revision": "<sha256-content-hash>",
  "status": "active|completed|archived"
}
```

Health commands include `"dashboardUrl"` and `"serviceState": "running|stopped|error"`.

## Commands

### `plan` / `plan open`
Ensure the service is available and open the dashboard. Optionally open a specific plan by ID or slug.
```
plan open [<id-or-slug>] [--remote [<name>]]
```

### `plan init`
Initialize and validate `~/Developer/plans` and its `archive/` subdirectory.

### `plan new <title>`
Create a plan and open it in `$EDITOR` (interactive).

### `plan create`
Create a plan non-interactively.
```
plan create --title "<title>" [--stdin | --file <file>] [--json]
```
Exit 0 on success. Exit 2 on invalid input. Writes a versioned JSON envelope to stdout.

Example — pipe Markdown from stdin:
```
echo "# My Plan\n\nSteps here." | plan create --title "My Plan" --stdin --json
```

### `plan import <file>`
Copy an existing `.md` file into the library with normalized metadata. Never modifies the source.

### `plan capture <artifact>`
Idempotently register a durable Markdown or standalone HTML plan artifact created outside the library.
```
plan capture <artifact> [--title "<title>"] [--json]
```
External Markdown is copied into the canonical library. HTML is converted to GitHub-flavored Markdown through Pandoc before it is written to the library. External sources are never modified. Unmanaged Markdown already inside the canonical library is normalized in place with plan-manager metadata. Recapturing the same absolute source updates the existing canonical plan only when converted content changed and preserves its ID and stable URL. Unsupported file types exit 2; unavailable HTML conversion exits 8.

### `plan list`
```
plan list [--status active|completed|archived] [--json]
```

### `plan search`
```
plan search "<query>" [--json]
```
Searches titles, tags, and Markdown content.

### `plan show`
```
plan show <id-or-slug> [--json]
```
Returns metadata and full Markdown in JSON mode.

### `plan edit <id-or-slug>`
Open the Markdown source in `$EDITOR` (interactive).

### `plan update`
Replace plan content non-interactively. Use `--if-revision` for optimistic concurrency.
```
plan update <id-or-slug> [--stdin | --file <file>] [--if-revision <revision>] [--json]
```
Exit 0 on success. Exit 5 on stale revision conflict (fetch current with `plan show --json` and retry). Exit 2 on invalid input and exit 4 on an ambiguous identifier.

Example — update with revision guard:
```
current_revision="$(plan show <id> --json | jq -r '.revision')"
echo "# Updated Plan\n\nNew content." | plan update <id> --stdin --if-revision "$current_revision" --json
```

### `plan status`
```
plan status <id-or-slug> active|completed|archived [--json]
```
Atomic status update.

### `plan archive`
```
plan archive <id-or-slug> [--json]
```
Moves plan into `archive/` via same-filesystem atomic rename.

### `plan serve`
```
plan serve [--foreground] [--json]
```
Ensure the loopback server is running idempotently at `http://plans.localhost:4173/`. Reports collision if port 4173 is occupied by another process. JSON response includes `dashboardUrl` and `serviceState`.

### `plan doctor`
```
plan doctor [--json]
```
Validate storage, Node.js, Pandoc, LaunchAgent state, port availability, and dashboard health. Reports a non-empty `~/.codex/AGENTS.override.md` as a conflict. JSON response includes all check results, `dashboardUrl`, and `serviceState`.

### `plan remote`
```
plan remote add <name> <url>
plan remote list [--json]
```
Stores service name and base URL. Never exposes credentials.

### `plan auth`
```
plan auth login [--remote <name>]
plan auth logout [--remote <name>]
```
Stores revocable scoped credential in the macOS Keychain.

### `plan push`
```
plan push <id-or-slug|--all> [--remote <name>] [--json]
```
Upload canonical Markdown to the configured hosted service. Invoke only after an explicit publish request. Returns local ID, hosted revision, content hash, and hosted URL. Exit 3 on stale hosted revision conflict.

### `plan remote status`
```
plan remote status <id-or-slug> [--remote <name>] [--json]
```

### `plan open --remote`
```
plan open <id-or-slug> --remote [<name>]
```
Open the stable authenticated hosted route.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | General failure |
| 2 | Invalid input |
| 3 | Plan not found |
| 4 | Ambiguous identifier |
| 5 | Stale local revision conflict |
| 6 | Path traversal rejected |
| 7 | Storage unavailable |
| 8 | Dependency unavailable or hosted capability not configured |
| 9 | Dashboard port collision |

## Ambiguous identifiers

When a slug or partial ID matches more than one plan the command exits 4 and lists candidates. Use the full stable ID to resolve.

## Path containment

All paths are resolved and checked against `~/Developer/plans` after normalization. Requests resolving outside that root are rejected without reading or modifying any file.
