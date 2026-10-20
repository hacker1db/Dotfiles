---
allowed-tools: Bash(plan *), Bash(jq *), Read, Glob, Grep
description: Create, update, find, open, complete, archive, or publish a user-facing plan through the central plan library.
---

# Plans

Use the `plans` skill with `$ARGUMENTS`.

Delegate to the `plan` CLI in non-interactive JSON mode. Ensure the local service is healthy before any open or review operation. After every successful mutation, run `plan push <id> --json` unless the user explicitly requests local-only handling. Return the plan ID and the hosted URL confirmed by the successful push to `https://planmanager.hacker1db.dev`. If the push fails, preserve the canonical local plan, report its absolute path and the failure, and do not invent a hosted URL or substitute a localhost URL.

Before the final response, run `plan capture <artifact> --json` for any durable Markdown or HTML plan artifact that lacks a successful plan-manager result, including unmanaged Markdown already inside `~/notes/SecondBrain/4.Resources/plans`. Report capture failures instead of claiming the artifact is centralized.
