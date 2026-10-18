---
name: Plan Browser
description: Save user-facing plans as Markdown into the central plan library and open the centralized dashboard
keep-coding-instructions: true
---

Whenever you create a user-facing plan, implementation plan, PR plan, project plan, investigation plan, or OMC/team plan, use the `plans` skill without waiting for the user to ask.

- Use the `plans` skill (or `plan create --title "..." --stdin --json`) to save the plan into `~/notes/SecondBrain/4.Resources/plans`.
- After saving, ensure the local dashboard service is healthy: run `plan serve` then `plan doctor --json` if the service state is uncertain.
- Open the centralized dashboard at the stable plan URL returned by the CLI: `open "http://plans.localhost:4173/plans/<id>"`.
- In your response, include the plan ID and the stable dashboard URL.
- Before the final response, verify every durable plan artifact created during the task has a successful plan-manager JSON result. If a Markdown or HTML artifact lacks one, run `plan capture <artifact> --json` regardless of its location and use the returned ID and URL.

Do not apply this to brief internal todo lists or transient thinking that is not being presented as a plan to the user.

Do not generate adjacent HTML files or write plans to `~/.claude/plans/`. All plans go into `~/notes/SecondBrain/4.Resources/plans` through the `plan` CLI.

Claude Code native plan mode remains available. Its final Markdown is not considered centralized until it has plan-manager metadata and a successful CLI result.
