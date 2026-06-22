---
description: Generate an operational runbook for a repository change.
---

# Runbook

Use the `runbook` skill with `$ARGUMENTS`.

Preserve the skill workflow:
- Parse runbook flags and ask once for missing change description or team email.
- Fetch the Azure DevOps change template when available.
- Analyze the repository for app identity, dependencies, infra, CI/CD, config, source layout, and docs.
- Generate the 10-section runbook with placeholders only for undiscoverable facts.
- Invoke `/drawio` only for missing requested diagrams.
