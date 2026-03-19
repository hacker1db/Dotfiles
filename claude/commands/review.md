---
description: Structured code review of staged changes across correctness, security, performance, clarity, maintainability, and style. Use this skill when the user asks to review staged changes, do a code review before committing, check their diff, or look at what's about to be committed. Triggers on "review my changes", "review staged", "check my diff", "code review", "look at what I changed".
---
First check: run `git diff --cached --stat`. If nothing is staged, report "No staged changes to review" and stop.

Analyze staged changes (`git diff --cached`) across: correctness, security, performance, clarity, maintainability, and style.

## Output Format

### Summary
Overall assessment (1-2 sentences) + counts by severity.

### Findings
For each issue:
- **Severity:** critical | high | medium | low | info
- **Category:** correctness | security | performance | clarity | maintainability | style
- **Location:** `file:line`
- **Issue:** concise title
- **Why it matters:** 1-sentence rationale
- **Recommendation:** actionable fix (include diff patch when the fix is clear)

### Good Practices
Briefly acknowledge 1-3 things done well.

### Top 3 Risks
Ordered list of the highest-priority issues to address before merging.

---
Highlight secrets, API keys, or unsafe patterns prominently. Keep findings concise and actionable only.
