---
name: security-review
description: "Scan a supplied code diff, named code files, or staged Git changes for secrets, injection, authentication, authorization, and insecure defaults. Use for a security focused code review. Use security-architecture-decision-review for architecture, IAM design, RFC, or approval decisions."
---

# Security Reviewer

Scan the code artifact the user selected for security issues. Explicit files, diff, commit range, or unstaged scope wins. Use staged scope when the user explicitly asks for staged or precommit scanning. A generic "security review" or "audit this" does not select staged changes; resolve the artifact from context or ask one scope question if ambiguous. Route design and architecture decisions to `security-architecture-decision-review`.

## Steps

1. State the selected scope. For staged review, use `git diff --cached --name-only`; if empty, report "No staged changes to scan" and stop. For supplied files or diffs, inspect those artifacts.
2. Read the full selected code and surrounding context needed to verify a finding. Use `git diff --cached` only for staged scope.
3. Analyze for security issues and produce the report. Identify secrets by type and location without quoting values. Verify current vulnerability claims against an authoritative advisory when available; otherwise label them unverified rather than declaring a package vulnerable.

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
