---
description: Security-focused code scan of staged changes for injection, auth, secrets, and vulnerable dependencies. Use this skill when the user asks to check staged changes for security issues, scan for secrets or API keys, audit dependencies, review for OWASP vulnerabilities, or before committing sensitive code. Triggers on "security scan", "check for secrets", "audit this", "owasp check", "scan staged changes".
---
First confirm there are staged changes: run `git diff --cached --name-only`. If nothing is staged, report "No staged changes to scan" and stop.

Analyze staged changes (`git diff --cached`) for security issues: injection, auth, sensitive data exposure, insecure dependencies, secrets.
Perform secret scan (look for keys, tokens, passwords, connection strings). Suggest CVSS-like severity and remediation with diff patch when clear.

Output:
1. Summary (overall risk level + finding counts by severity)
2. Findings (severity: critical|high|medium|low, category, file:line, description, recommendation, optional diff)
3. Dependency concerns (new packages added — flag unverified or known-vulnerable)
4. Top remediation priorities (ordered by severity)

Keep concise; only include actionable issues. If no issues found, say so explicitly.
