## Why

The local plan dashboard renders Markdown task-list syntax as text because its sanitizer removes every HTML input. Users cannot visually review or persist selections in plan checklists such as the Homebrew tool audit.

## What Changes

- Render Markdown task-list markers as accessible, selectable checkboxes in local plan detail views.
- Persist a checkbox toggle by changing only the matching `- [ ]` or `- [x]` marker in canonical Markdown.
- Add a same-origin, CSRF-protected, revision-checked task-toggle endpoint that uses the existing writer lock and atomic write path.
- Preserve the current raw-HTML restrictions: only checkboxes generated from Markdown task-list syntax can become interactive.
- Add dashboard, mutation, conflict, and sanitization regression coverage.

## Impact

- Affected specification: `plan-management`
- Affected application repository: `~/Developer/sites/plan-manager/main`
- Affected code: server rendering and mutation routes, plan-detail dashboard JavaScript and CSS, dashboard tests
- No hosted service, remote API, or plan-library migration changes
