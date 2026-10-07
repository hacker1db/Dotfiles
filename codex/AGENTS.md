# Codex Global Plan Policy

## User-facing plans

A **user-facing plan** is an implementation plan, project plan, investigation, migration, deployment plan, or other durable deliverable presented to the user as a plan artifact.

This policy applies when a user asks to create, save, update, find, review, open, complete, archive, or explicitly publish a user-facing plan.

**Excluded** from this policy:
- Transient reasoning or scratch thinking during a task
- Brief internal task lists that are not presented as deliverables
- Codex native planning mechanics and scratch state (`/plan`) — preserve them as-is. Any durable plan or visualization finalized from that mode remains subject to the central-library finalization guard.

## Central plan library

For every in-scope plan:

1. Use `~/Developer/plans` as the canonical library. Do not create a Codex-specific copy.
2. Delegate all operations to the `plan` executable in non-interactive JSON mode (`--json`).
3. Before opening or reviewing a plan, ensure the local service is healthy: run `plan serve` then `plan doctor --json`. Report failures without fabricating a dashboard URL.
4. Return the plan ID and stable local dashboard URL (`http://plans.localhost:4173/plans/<id>`) from every mutation.
5. Invoke `plan push` only after an explicit publish request from the user.
6. Before the final response, verify that every durable plan artifact created during the task has a successful plan-manager JSON result. If a Markdown or HTML artifact lacks one, run `plan capture <artifact> --json` regardless of where Codex wrote it. If capture fails, report the artifact path and failure instead of claiming it is centralized.

## Adapter

Invoke the `plans` skill (available as `$plans` or through `/skills`) to handle plan operations. The skill delegates everything to the `plan` CLI and does not reimplement storage or server behavior.

## Workspace access

The plan library at `~/Developer/plans` is configured as a writable root in `~/.codex/config.toml`. If a managed application or organization policy prevents write access, request approval when prompted and do not attempt to bypass the sandbox.

## Model

Do not change the model setting for plan operations.

## Native planning mode

The built-in Codex `/plan` command is not replaced by this policy. Use `$plans` or `/skills` to access the central plan manager and `/plan` for native planning as usual. Before returning a durable plan or visualization from native mode, persist or capture it through the central CLI.
