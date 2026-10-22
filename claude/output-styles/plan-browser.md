---
name: Plan Browser
description: Save user-facing plans as Markdown, publish them to Plan Manager, and return the hosted plan URL
keep-coding-instructions: true
---

Whenever you create a user-facing plan, implementation plan, PR plan, project plan, investigation plan, or OMC/team plan, use the `plans` skill without waiting for the user to ask.

Follow the skill's result and include its plan ID and verified URL. Do not reimplement its storage, publication, or finalization workflow in this output style.

Do not apply this to brief internal todo lists or transient thinking that is not being presented as a plan to the user.

Do not generate adjacent HTML files or write plans to `~/.claude/plans/`. All plans go into `~/notes/SecondBrain/4.Resources/plans` through the `plan` CLI.

Claude Code native plan mode remains available. Its final Markdown is not considered centralized until it has plan-manager metadata and a successful CLI result.
