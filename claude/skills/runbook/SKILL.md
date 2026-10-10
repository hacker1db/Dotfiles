---
name: runbook
description: "Draft or revise an operational runbook from repository evidence, with implementation, validation, rollback, and optional architecture diagrams. Use for deployment procedures and operational guides. Wiki publication and PDF export require a user request; executing the procedure is separate."
---

# Runbook Generator

Produce a complete local runbook using `references/template.md`. Read its ten section contract before drafting and `references/repo-analysis.md` when examining the repository.

## Inputs and workflow

1. Use the change description and repository from the conversation. Accept free text or `--cr <NUM>`, `--date <YYYY-MM-DD>`, `--tier <0-3>`, `--diagrams <conceptual,physical,network,dataflow>`, and `--email <ADDRESS>`. Missing team email can remain a placeholder; it is not a drafting prerequisite.
2. Fetch a specified, accessible wiki template when available; otherwise use the bundled template. Inspect application identity, dependencies, infrastructure, pipelines, configuration, source structure, and existing documentation.
3. Draft all ten sections. Cite the evidence for operational commands, distinguish proposed steps, and mark unknown fields `[PLACEHOLDER - description]`. Documenting a procedure does not authorize running it.
4. Reuse relevant diagrams. Create requested missing diagrams through the available diagram capability, using the drawio skill for editable files. Parallel work is optional when the host supports it. Embed completed files with valid relative paths and report unavailable rendering capabilities.
5. Save Markdown to the requested destination or `Docs/{app_name}-Runbook.md`. Produce a PDF only when requested using an available converter. Check all sections, commands, rollback assumptions, and links before delivery.

## Publication

Publish to a wiki only when the user has authorized that destination in this conversation. Honor existing authorization without asking again. Otherwise deliver the complete local draft before requesting a publishing decision. Missing wiki coordinates need not delay drafting. Verify the remote page before claiming publication; retain the local draft on failure.
