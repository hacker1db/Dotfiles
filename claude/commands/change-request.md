---
description: Generate a formal Change Request document from the current repository.
---

# Change Request

Use the `change-request` skill with `$ARGUMENTS`.

Preserve the skill workflow:
- Parse CR flags and missing required inputs.
- Fetch the authoritative Azure DevOps wiki template when available.
- Analyze the repository for app identity, infra, CI/CD, dependencies, data stores, integrations, and observability.
- Produce the CR document using placeholders only for facts that cannot be discovered.
- Save/publish according to the skill instructions.
