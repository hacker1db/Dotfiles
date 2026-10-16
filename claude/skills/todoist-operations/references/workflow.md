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

Resolve the active vault and inspect its existing folders before filing. For David's SecondBrain vault, verified destinations are:

1. General references: `4.Resources/` or an existing relevant subfolder. Reader synced articles live at `4.Resources/Readwise/Articles/`; use Reader save workflows for that managed collection.
2. Ideas: `0.Quick Notes 📨/` unless a more specific existing project destination is established. There is no verified `Raw Ideas` folder; do not invent one from the former path.
3. Journal and reflections: `2.Areas/Personal Home/Journal/`.
4. Grouped tasks: resolve the existing project structure before creating an Obsidian or Todoist project within the authorized task.

Verify the destination note was saved successfully before commenting with its link or completing the source task. Preserve Obsidian metadata and links. Recheck folders on other machines rather than assuming this vault layout.

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
