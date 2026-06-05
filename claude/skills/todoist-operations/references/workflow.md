# Todoist Workflow

## Core Principles

1. Default No - only say yes to the highest-leverage moves toward the goal.
2. Finishing Over Starting - prioritize the final 20% of work that gets something done.
3. 5-7 Tasks Per Day Maximum - if overloaded, triage to future dates or remove dates.

## Task Categories

| Category | Action |
| --- | --- |
| Sprint Work with clear done state | Keep due date, prioritize |
| Wisdom/Philosophy | Remove date, keep in backlog |
| Ideas and Experiments | Move to Ideas project, remove date |
| Delegated with assignee | Verify assignment, skip |
| Vague or unclear | Clarify or delete |
| Admin or drudgery | Batch, delegate, or delete |

## Content Destinations

- Articles/References -> `3-Resources/Articles/` in Obsidian
- Ideas -> `3-Resources/Raw Ideas/` with full context
- Journal/Reflections -> `2-Areas/Journal/`
- Grouped tasks -> create Obsidian project and Todoist project

## Processing Output Format

```markdown
| # | Task | Due | Action | Project | Reasoning | Conf |
|---|------|-----|--------|---------|-----------|------|
| 1 | Ship snapshot | Oct 3 | Keep | Current | Sprint work, final 20% | 95% |
| 2 | Read philosophy | Oct 3 | Remove date | Inbox | Timeless | 90% |
```

Confidence thresholds:

- 90%+ = execute without asking if the user already authorized changes.
- 70-90% = show for quick review.
- Less than 70% = ask for guidance.

## Collaboration Protocol

1. Read comments before categorizing.
2. Check for attachments; images may have empty content.
3. Propose categories for each batch.
4. Get user confirmation before executing changes unless the user already gave explicit execution instructions.
5. Add Todoist URL to Obsidian notes as a `todoist:` frontmatter field.
6. Comment on tasks with destination links before completing.
