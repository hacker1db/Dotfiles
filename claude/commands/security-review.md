---
description: Security-focused code scan of staged changes for injection, auth, secrets, and vulnerable dependencies
---
Analyze staged changes for security issues: injection, auth, sensitive data exposure, insecure dependencies, secrets.
Perform secret scan (look for keys, tokens). Suggest CVSS-like severity and remediation with diff patch when clear.
Output:
1. Summary (risk level + counts)
2. Findings (severity, category, file:line, description, recommendation, optional diff)
3. Dependency concerns (list if any)
4. Top remediation priorities (ordered list)
Keep concise; only include actionable issues.
