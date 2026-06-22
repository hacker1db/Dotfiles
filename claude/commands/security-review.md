---
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(git show:*), Bash(git remote show:*), Bash(sonar-scanner:*), Bash(curl:*), Bash(jq:*), Read, Glob, Grep, LS, Task
description: Complete a focused security review of the pending branch changes.
---

# Security Review

Use the `security-review` skill with `$ARGUMENTS`.

Review only security implications introduced by the pending changes. Prioritize high-confidence findings in changed files, filter out theoretical hardening advice, dependency-age noise, DoS-only issues, and documentation-only concerns, and report actionable findings with file/line, severity, exploit scenario, and fix recommendation.
