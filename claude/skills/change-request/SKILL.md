---
name: change-request
description: "Draft a formal deployment Change Request from repository evidence, including risk, validation, and rollback. Use for creating or revising CR documents. Publish to an Azure DevOps wiki only when requested; deployment execution and general code review are separate tasks."
---

# Change Request Generator

Produce a complete local Change Request using `references/template.md` and repository evidence. Read the template before drafting and `references/repo-analysis.md` when inspecting the repository.

## Inputs and workflow

1. Use the requested change, repository, and destination from the conversation. Accept free text or `--cr <NUMBER>`, `--date <YYYY-MM-DD>`, `--window <HH:MM-HH:MM TZ>`, `--type <standard|emergency|normal>`, `--risk <low|medium|high|critical>`, `--env <ENV>`, and `--runbook <PATH>`.
2. Fetch an existing wiki template if its location and authenticated access are available. Otherwise use the bundled template. Ask only for details necessary to resolve the change scope; mark other missing fields `[PLACEHOLDER - description]`.
3. Inspect application identity, infrastructure, pipelines, dependencies, configuration, and source structure. Assess blast radius, data impact, failure modes, and rollback complexity. Distinguish repository facts from proposed steps.
4. Save all ten sections as Markdown in the requested destination or the project's documentation folder. Generate a PDF only when requested, using an available document conversion capability.
5. Check completeness, paths, and consistency before delivering the local draft. Drafting procedures does not authorize executing them.

## Publication

A draft request authorizes the local document. Publish only when the user has authorized publication to the destination in this conversation. Honor prior authorization without asking again. If it is absent, deliver the complete draft before requesting a publishing decision. Resolve missing destination details only when publication is needed. Verify the remote result before reporting success; preserve the local draft if publication fails.
