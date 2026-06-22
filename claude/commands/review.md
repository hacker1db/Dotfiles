---
description: Review staged changes for correctness, security, performance, clarity, and maintainability.
---

# Review

Use the `review` skill with `$ARGUMENTS`.

Check staged changes first. If nothing is staged, report that and stop. Otherwise review `git diff --cached` and return concise, actionable findings with severity, category, file/line, rationale, and recommendation.
