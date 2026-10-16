# Skill Creator — Skill Anatomy & Writing Guide

## File Structure

```
skill-name/
├── SKILL.md          (required — main skill file)
├── scripts/          (optional — executable code)
│   ├── process.py
│   └── validate.sh
├── references/       (optional — docs loaded as needed)
│   ├── api-guide.md
│   └── examples/
└── assets/           (optional — templates, fonts, icons)
    └── report-template.md
```

## SKILL.md Structure

```markdown
---
name: your-skill-name          # kebab-case, no spaces, no capitals
description: "What it does. Use when user asks to [specific phrases].
              Include both WHAT it does AND WHEN to use it."
---

# Skill Title

Brief overview (1–2 sentences).

## Quick Reference
...

## References

- `references/guide.md` — When and how to use it
```

## YAML Frontmatter Field Requirements

**`name`** (required):
- kebab-case only
- No spaces or capitals
- Should match folder name

**`description`** (required):
- Under 1024 characters
- Must include BOTH: what the skill does + when to use it (trigger conditions)
- No XML tags (`<` or `>`)
- Include specific user phrases and file types
- Be "pushy" — skills undertrigger by default; make it clear when to invoke

## Progressive Disclosure

Skills load in three levels:

| Level | Content | When loaded |
|-------|---------|------------|
| 1st | YAML frontmatter (name + description) | Always in context |
| 2nd | SKILL.md body | When skill is triggered |
| 3rd | Files in references/, assets/ | On demand, as needed |

This minimizes token usage. Keep SKILL.md under 200 words. Put technical depth in `references/`.

## Writing Patterns

**Define output formats explicitly:**
```markdown
## Output Structure
ALWAYS use this exact template:
# [Title]
## Executive Summary
## Key Findings
## Recommendations
```

**Use examples:**
```markdown
**Example:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

**Explain the why:**
Instead of `ALWAYS do X`, explain: "Do X because Y helps the user accomplish Z." LLMs perform better when they understand the reasoning.

**Prefer imperative form:** "Extract the table," not "You should extract the table."

## SKILL.md Naming Rules

- File must be exactly `SKILL.md` (case-sensitive)
- No variations: not SKILL.MD, skill.md, Skill.md
- No README.md inside skill folders

## Skill Folder Naming Rules

- kebab-case only: `notion-project-setup` ✓
- No spaces: `Notion Project Setup` ✗
- No underscores: `notion_project_setup` ✗
- No capitals: `NotionProjectSetup` ✗

## Domain Organization

When a skill supports multiple variants, organize by variant:

```
cloud-deploy/
├── SKILL.md       (workflow overview + variant selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

Claude reads only the relevant reference file, saving tokens.

## When to Use references/

- File would exceed 200-line SKILL.md — add a hierarchy layer
- Large reference files (>300 lines) — include a table of contents at top
- Multiple variants of the same workflow (see domain organization above)
- Reusable scripts that multiple test cases would reinvent independently
