---
name: security-review
description: "Security-focused scan of staged git changes for injection, auth issues, secrets, and vulnerable dependencies. Use this skill when the user asks to check staged changes for security issues, scan for secrets or API keys, audit dependencies, review for OWASP vulnerabilities, or before committing sensitive code. Triggers on 'security scan', 'check for secrets', 'audit this', 'owasp check', 'scan staged changes', 'security review', 'check for api keys', 'scan for vulnerabilities'."
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
