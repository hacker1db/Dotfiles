## Context

Plan Markdown is canonical and the local dashboard already supports authenticated status and archive mutations. Pandoc emits task-list checkbox inputs for Markdown markers, but the current sanitizer removes every input element to prevent active content. The dashboard therefore cannot expose task selection or persist a user's checklist choices.

## Goals / Non-Goals

- Goals: visible accessible checkboxes for Markdown task items, atomic persistence to canonical Markdown, same-origin CSRF protection, stale-revision protection, and no expansion of the trusted HTML surface.
- Non-Goals: browser Markdown editing, arbitrary form support, shared or remote checklist state, and changing non-task Markdown.

## Decisions

### Canonical task representation

The Markdown marker remains canonical. A successful toggle changes only one line-start task marker between `- [ ]` and `- [x]`, preserving all other bytes and frontmatter. The dashboard refreshes from the resulting plan revision.

### Toggle identity and concurrency

The browser sends the zero-based rendered task index, requested boolean state, and the plan revision it displayed. The server derives the matching task marker from the current canonical Markdown while holding the existing writer lock. A stale revision receives a conflict response and does not change the file.

### Rendering and safety

The Markdown renderer continues to disable raw HTML and raw attributes. The sanitizer permits only checkbox inputs emitted by Pandoc for task-list syntax, after constraining the allowed attributes to checkbox type, checked state, and disabled state. Dashboard JavaScript enables only those generated checkboxes and never interprets plan-body HTML as executable behavior.

### Mutation endpoint

Add a same-origin `POST /api/plans/:id/tasks/:index` endpoint. It validates the request body, plan ID, task index, requested boolean state, CSRF token, Host, Origin, and current revision; it uses the existing atomic plan write and returns the new revision.

## Risks / Trade-offs

- Task index can change when another writer edits the plan. Revision checking prevents a toggle from changing an unintended item.
- Enabling inputs expands the rendered DOM surface. Restricting raw HTML before Pandoc and allowlisting only generated checkbox attributes keeps the current XSS defense intact.
- A dashboard refresh after mutation is simpler and more reliable than optimistic client-side Markdown reconstruction.
