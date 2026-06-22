---
name: runbook
description: "Generate an operational runbook from repo analysis with optional draw.io diagrams. Triggers: create runbook, deployment procedure, implementation steps, operational guide."
---

# Runbook Generator

Analyze the current repo and produce a complete operational runbook with architecture diagrams, then publish to Azure DevOps wiki.

## Arguments

Parse `$ARGUMENTS`: free text = change description; `--cr <NUM>`, `--date <YYYY-MM-DD>`, `--tier <0-3>`, `--diagrams <conceptual,physical,network,dataflow>`, `--email <ADDRESS>`.

If no description or `--email`, ask before proceeding.

## Workflow (4 Steps)

1. **Fetch ADO CR template** — ask user for org/project/wiki/path; use template as the authoritative structure
2. **Analyze repository** — app identity, dependencies, infra, CI/CD, Kubernetes, config, source structure, existing docs
3. **Generate runbook** — all 10 sections auto-populated from analysis; use `[PLACEHOLDER - description]` for unknowns
4. **Save & publish** — save to `Docs/{app_name}-Runbook.md`, generate PDF (`npx md-to-pdf --stylesheet ~/.dotfiles/claude/md-to-pdf.css`), launch parallel `/drawio` agents for missing diagrams, embed diagrams, publish to ADO wiki

See `references/template.md` for the full 10-section output structure and `references/repo-analysis.md` for what to scan.
