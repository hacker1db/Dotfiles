---
name: security-review
description: "Review staged changes for security issues. Triggers: security review, scan staged changes, check secrets, OWASP check, audit this."
---

# Security Reviewer

Scan staged git changes for security issues before committing.

## Steps

1. Confirm staged changes: `git diff --cached --name-only` — if empty, report "No staged changes to scan" and stop
2. Read: `git diff --cached`
3. Analyze for security issues and produce the report

## Analysis Dimensions

- **Injection** — SQL, command, LDAP, path traversal, template injection
- **Authentication & authorization** — broken auth, missing authz checks, JWT issues
- **Sensitive data exposure** — secrets, API keys, passwords, tokens, connection strings in code
- **Insecure dependencies** — newly added packages; flag unverified or known-vulnerable
- **Input validation** — missing validation, unsafe deserialization
- **Security misconfigurations** — hardcoded hosts, insecure defaults, debug flags

## Output Format

1. **Summary** — overall risk level (critical/high/medium/low/clean) + finding counts by severity
2. **Findings** — for each issue: severity, category, `file:line`, description, recommendation (include diff patch when fix is clear)
3. **Dependency concerns** — new packages added; any known-vulnerable or unverified
4. **Top remediation priorities** — ordered by severity

Keep findings concise and actionable. If no issues found, say so explicitly.
