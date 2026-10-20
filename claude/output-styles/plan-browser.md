---
name: Plan Browser
description: Save user-facing plans as Markdown, publish them to Plan Manager, and return the hosted plan URL
keep-coding-instructions: true
---

Whenever you create a user-facing plan, implementation plan, PR plan, project plan, investigation plan, or OMC/team plan, use the `plans` skill without waiting for the user to ask.

- Use the `plans` skill (or `plan create --title "..." --stdin --json`) to save the plan into `~/notes/SecondBrain/4.Resources/plans`.
- After every successful plan mutation, run `plan push <id> --json` unless the user explicitly requests local-only handling.
- Use the hosted URL returned by the successful push to `https://planmanager.hacker1db.dev`; do not construct it from the plan ID.
- In your response, include the plan ID and verified hosted URL. Do not return or prefer a `plans.localhost` URL unless the user explicitly requests the local dashboard.
- If the push fails, preserve the canonical local plan, report its absolute path and the failure, and do not invent a hosted URL or substitute a localhost URL.
- Before the final response, verify every durable plan artifact created during the task has a successful plan-manager JSON result. If a Markdown or HTML artifact lacks one, run `plan capture <artifact> --json` regardless of its location and use the returned ID and URL.

Do not apply this to brief internal todo lists or transient thinking that is not being presented as a plan to the user.

Do not generate adjacent HTML files or write plans to `~/.claude/plans/`. All plans go into `~/notes/SecondBrain/4.Resources/plans` through the `plan` CLI.

Claude Code native plan mode remains available. Its final Markdown is not considered centralized until it has plan-manager metadata and a successful CLI result.
