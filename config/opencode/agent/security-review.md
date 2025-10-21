# Security Review Agent

**Command:** `/security-review`  
**Aliases:** `/sec`, `/security`  
**Provider:** Anthropic Claude Sonnet  
**Type:** Secondary Agent

## Purpose

Security-focused code review agent that scans for vulnerabilities, secrets, security anti-patterns, and provides CVSS-scored remediation guidance.

## Configuration

```yaml
model:
  provider: anthropic
  name: claude-3-5-sonnet-20241022
  temperature: 0.1
  max_tokens: 8192
```

## Scan Types

- **Secrets**: Exposed credentials, API keys, tokens
- **Vulnerabilities**: CVE-mapped security flaws
- **Misconfigurations**: Insecure settings
- **Insecure Patterns**: Common anti-patterns

## Secret Patterns

- `aws_access_key_id`
- `aws_secret_access_key`
- `github_token`
- `private_key`
- `api_key`, `api-key`
- `password`
- `bearer` tokens

## Vulnerability Sources

- **NVD**: National Vulnerability Database
- **GitHub Advisories**
- **Snyk**: Dependency vulnerabilities
- **OSV**: Open Source Vulnerabilities

## System Prompt

```
You are a security expert specializing in application security and vulnerability analysis.
Your role is to identify security issues, rate their severity using CVSS-like scoring, and provide remediation guidance.

Focus Areas:
- Injection vulnerabilities (SQL, Command, XSS, etc.)
- Authentication and authorization flaws
- Sensitive data exposure
- Insecure dependencies
- Security misconfigurations
- Cryptographic failures
- Insufficient logging and monitoring

Output structured findings with CVE references when applicable.
```

## Input Sources

- Git diff (staged)
- Full files (for context)
- Dependency manifests (package.json, requirements.txt, go.mod, etc.)

## Preprocessing

- Secret scan
- Dependency vulnerability check
- SAST (Static Application Security Testing)

## Integrations

### Scanners

- **Trivy** (enabled) - Container & dependency scanner
- **Semgrep** (enabled, security ruleset) - SAST
- **Gitleaks** (enabled) - Secret detection
- **Snyk** (disabled by default) - Dependency analysis

## Output Format

```markdown
## Security Review Report

### Summary
- Risk Level: Critical/High/Medium/Low
- Vulnerabilities Found: N
- Secrets Detected: N
- Dependencies Scanned: N

### Findings

#### [CVE-2024-XXXXX] SQL Injection in User Query
**Severity:** Critical (CVSS 9.8)  
**Category:** Injection  
**File:** `src/database/queries.js:42`

**Description:**
User input is directly interpolated into SQL query without sanitization.

**Recommendation:**
Use parameterized queries or ORM with prepared statements.

**Suggested Fix:**
\`\`\`diff
- const query = `SELECT * FROM users WHERE id = ${userId}`;
+ const query = `SELECT * FROM users WHERE id = ?`;
+ db.execute(query, [userId]);
\`\`\`

**References:**
- CWE-89: SQL Injection
- OWASP A03:2021 - Injection
```

## Rate Limiting

- **Requests per minute**: 30
- **Burst size**: 5

## Caching

- **Enabled**: Yes
- **TTL**: 1800 seconds (30 minutes)

## Usage

```bash
# Security scan of staged changes
/security-review

# Quick alias
/sec

# Full security scan
/security
```

## Environment Variables

```bash
export ANTHROPIC_API_KEY="your-anthropic-key"

# Optional integrations
export SNYK_TOKEN="your-snyk-token"
export TRIVY_DB_REPOSITORY="ghcr.io/aquasecurity/trivy-db"
```

## Capabilities

- Static analysis
- Vulnerability scanning
- Secret detection
- Dependency auditing
