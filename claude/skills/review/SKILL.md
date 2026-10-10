---
name: review
description: "Review a staged Git diff before commit, or a supplied code diff for correctness, maintainability, performance, and style. Use for staged review, precommit review, or checking a specific diff. Use pr-review for a branch or pull request and security-review for a security focused code scan."
---

# Code Diff Reviewer

Review the artifact the user selected. Explicit scope wins, including an attached diff, named files, unstaged changes, or a commit range. A generic request such as "check my diff" does not select the index. Use context to resolve it; if staged and unstaged changes both exist and scope remains unclear, ask which to review before making findings. Route branch or pull request reviews to `pr-review` and security only scans to `security-review`.

## Steps

1. Resolve and state the review scope. For explicit staged or precommit review, check `git diff --cached --stat`; if empty, report "No staged changes to review" and stop. For other scopes, inspect the selected artifact and identify its boundaries.
2. Read the full selected diff and enough surrounding code to validate findings. Use `git diff --cached` only for staged scope. Analyze all six dimensions below unless the user narrowed the focus.
3. Produce the report. Cite verified locations and distinguish observed defects from unverified risks. Never reproduce secret values; identify their location and type.

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
