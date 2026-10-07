## 1. Safe task persistence

- [x] 1.1 Add a revision-checked task-marker update helper that changes only canonical Markdown task syntax under the existing writer lock and atomic-write path.
- [x] 1.2 Add the same-origin, CSRF-protected task-toggle route with strict ID, index, boolean, body-size, and stale-revision validation.

## 2. Interactive dashboard rendering

- [x] 2.1 Preserve only renderer-generated task-list checkbox inputs through sanitization while retaining the raw-HTML and raw-attribute restrictions.
- [x] 2.2 Enable rendered task checkboxes in the plan-detail view, submit revision-checked toggles, prevent double submission, and refresh the plan after success or conflict.
- [x] 2.3 Add focused dashboard styling and accessible labels for selectable task items.

## 3. Verification

- [x] 3.1 Add server tests for successful check/uncheck persistence, invalid indices and bodies, stale revisions, CSRF rejection, and atomic preservation of unrelated Markdown.
- [x] 3.2 Add rendering tests that task-list checkboxes survive while raw input, form, script, event-handler, and unsafe-URL injection remain blocked.
- [x] 3.3 Run the plan-manager TypeScript build and full test suite; verify the Homebrew audit can be selected in the local dashboard.
