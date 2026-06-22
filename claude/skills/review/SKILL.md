---
name: review
description: "Review staged git changes for correctness and maintainability. Triggers: review staged, check my diff, code review, review before commit."
---

# Staged Changes Reviewer

Review staged git changes before a commit. If nothing is staged, stop immediately.

## Steps

1. Check: `git diff --cached --stat` — if empty, report "No staged changes to review" and stop
2. Analyze: `git diff --cached` across all six dimensions below
3. Produce the report

## Report Format

**Summary** — overall assessment (1-2 sentences) + counts by severity: critical, high, medium, low, info.

**Findings** — for each issue:
- Severity: `critical | high | medium | low | info`
- Category: `correctness | security | performance | clarity | maintainability | style`
- Location: `file:line`
- Issue: concise title
- Why it matters: 1 sentence
- Recommendation: actionable fix (include diff patch when the fix is clear)

**Good Practices** — 1-3 things done well.

**Top 3 Risks** — highest-priority issues to address before committing.

Always highlight secrets, API keys, and unsafe patterns prominently.
