---
name: todoist-operations
description: "Manage the user's Todoist tasks through the Todoist REST and Sync APIs. Use when creating tasks, processing or triaging Todoist, reading task comments, moving/completing tasks, or when the user says 'my tasks', 'todoist', 'task management', 'process my tasks', or 'help with my Todoist'."
---

# Todoist Operations

Use this skill for Todoist task creation, triage, moving, commenting, and completion.

Rules:

- Do not create or change tasks unless the user asks.
- Fetch task comments before acting; they may contain required links, images, or notes.
- For batches, fetch all relevant tasks, present the full numbered set, then process from the user's instructions.
- Treat tasks assigned to someone else as delegated.
- Before completing a task moved elsewhere, add a Todoist comment with the destination link.
- For shell, Python, MCP, or external-tool workflows, pull the API key from 1Password with `op` item `Todoist api`; never ask the user to paste it or persist it to files.

## References

- `references/credentials.md` - Token retrieval from 1Password.
- `references/api.md` - API helpers, project IDs, priorities, and operations.
- `references/workflow.md` - GTD triage rules, output format, and protocol.
