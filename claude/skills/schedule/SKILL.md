---
name: schedule
description: "Create a scheduled or repeatable task. Triggers: schedule this, run every day, remind me, automate this, save as task."
---

# Schedule Skill

Captures a workflow from the current session and registers it as a scheduled task.

## Steps

**1. Analyze the session** — Identify the core repeatable task from conversation history.

**2. Draft a self-contained prompt** — Future runs have zero session context. Include: objective, specific steps, file paths or URLs, expected output, and constraints. Write in second-person imperative ("Check the inbox…").

**3. Choose a taskName** — Short kebab-case (e.g. `daily-inbox-summary`, `weekly-dep-audit`).

**4. Determine schedule** — Pick one:

- **Recurring** → `cronExpression` in LOCAL time (e.g. `0 9 * * 1-5` = weekdays 9 AM)
- **One-time** → `fireAt` ISO 8601 with offset (e.g. `2026-03-20T14:30:00-08:00`)
- **Ad-hoc** → omit both fields
- **Ambiguous** → propose a schedule and ask the user to confirm

**5. Call `create_scheduled_task`** with taskId, prompt, description, and schedule.

## References

- `references/cron-examples.md` — Common cron patterns and timezone notes
