---
name: plans
description: "Create, save, update, find, review, open, complete, archive, or publish a user-facing plan. Triggers: create plan, save plan, update plan, find plan, open plan, complete plan, archive plan, publish plan, plan manager, plan library, plan dashboard."
---

# Plans

Manage user-facing plans through the central `plan` CLI and local dashboard.

## Trigger boundary

Use this skill when the user asks to **create, save, update, find, review, open, complete, archive, or explicitly publish** a user-facing plan: an implementation plan, project plan, investigation, migration, deployment plan, or other durable deliverable presented to the user.

Do **not** use this skill for:
- Transient reasoning or scratch thinking
- Brief internal task lists that are not deliverables
- Native `/plan` mechanics or built-in planning scratch state — preserve those as-is. A durable plan finalized by a native mode is still in scope for the finalization guard.

## Workflow

1. **Ensure service health** before any open/review operation: run `plan serve` then `plan doctor --json` to confirm the dashboard is reachable. Report failures without claiming the URL is available.
2. **Delegate all operations to the `plan` CLI** in non-interactive JSON mode (`--json`). Never edit canonical Markdown files directly. Never call dashboard mutation endpoints.
3. **Use optimistic revisions** for updates: pass `--if-revision <revision>` from the previous JSON result. On conflict, fetch current revision with `plan show <id> --json` and retry or report.
4. **Return the plan ID and stable local dashboard URL** (`http://plans.localhost:4173/plans/<id>`) from every mutation result.
5. **Invoke `plan push` only** after an explicit publish request or an already-configured user policy. When pushing, also return the hosted URL from the response envelope.
6. **Report failures faithfully**: if the CLI exits non-zero, surface the error and do not claim the plan was saved, updated, or published.
7. **Run the finalization guard** before returning a durable plan: verify that every plan artifact created during the task has a successful plan-manager JSON result. If a Markdown or HTML artifact lacks one, run `plan capture <artifact> --json` regardless of where the harness wrote it. This normalizes unmanaged Markdown already inside `~/Developer/plans` and imports or converts external artifacts. Return the captured plan ID and stable dashboard URL. If capture fails, report the artifact path and failure instead of claiming it is centralized.

## Key commands

| Intent | Command |
|---|---|
| Create (non-interactive) | `plan create --title "..." --stdin --json` |
| Capture external Markdown or HTML | `plan capture <artifact> --json` |
| Update with revision guard | `plan update <id> --stdin --if-revision <rev> --json` |
| List all | `plan list --json` |
| Search | `plan search "..." --json` |
| Show / open | `plan show <id> --json` |
| Complete | `plan status <id> completed --json` |
| Archive | `plan archive <id> --json` |
| Ensure service running | `plan serve --json` |
| Health check | `plan doctor --json` |
| Publish (explicit only) | `plan push <id> --json` |

See `references/cli.md` for full syntax, JSON schema, and exit codes.
See `references/server.md` for service health workflow and dashboard URL details.
See `references/remote.md` for opt-in publishing, auth, and conflict handling.
