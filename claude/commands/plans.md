---
allowed-tools: Bash(plan *), Bash(jq *), Read, Glob, Grep
description: Create, update, find, open, complete, archive, or publish a user-facing plan through the central plan library.
---

# Plans

Use the `plans` skill with `$ARGUMENTS`.

Delegate to the `plan` CLI in non-interactive JSON mode. Ensure the local service is healthy before any open or review operation. Return the plan ID and stable dashboard URL (`http://plans.localhost:4173/plans/<id>`) from every mutation. Invoke `plan push` only on an explicit publish request.

Before the final response, run `plan capture <artifact> --json` for any durable Markdown or HTML plan artifact that lacks a successful plan-manager result, including unmanaged Markdown already inside `~/Developer/plans`. Report capture failures instead of claiming the artifact is centralized.
