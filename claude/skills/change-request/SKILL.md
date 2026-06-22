---
name: change-request
description: "Generate a formal Change Request document from repo analysis. Triggers: create CR, write change request, generate CR, deployment approval."
---

# Change Request Generator

Analyze the current repo and produce a complete CR document with risk assessment, rollback plan, and ADO wiki publish.

## Arguments

Parse `$ARGUMENTS` for flags: `--cr <NUMBER>`, `--date <YYYY-MM-DD>`, `--window <HH:MM-HH:MM TZ>`, `--type <standard|emergency|normal>`, `--risk <low|medium|high|critical>`, `--env <ENV>`, `--runbook <PATH>`.

## Workflow

1. **Fetch template** — pull the CR template from the ADO wiki (ask user for org/project/wiki/path)
2. **Analyze repo** — scan for app identity, infra, CI/CD, dependencies, config, source structure
3. **Assess risk** — blast radius, data impact, rollback complexity, failure modes
4. **Generate document** — all 10 sections (description, risk, prerequisites, implementation steps, validation, rollback, systems, comms, diagrams, close checklist)
5. **Save & publish** — write to `~/Downloads/CR-{cr_number}-{app_name}/`, generate PDF via `npx md-to-pdf --stylesheet ~/.dotfiles/claude/md-to-pdf.css`, publish to ADO wiki

Use `[PLACEHOLDER - description]` for fields that cannot be auto-detected from the repo.

## References

- `references/template.md` — full 10-section CR output template and section details
- `references/repo-analysis.md` — what to scan and how to populate fields
