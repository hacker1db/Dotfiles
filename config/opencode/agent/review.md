# Code Review Agent

**Command:** `/review`  
**Aliases:** `/code-review`, `/cr`  
**Provider:** GitHub Copilot (GPT-4)  
**Type:** Primary Agent

## Purpose

Comprehensive code review agent that analyzes diffs, identifies issues across multiple dimensions, and suggests improvements with inline patches.

## Configuration

```yaml
model:
  provider: copilot
  name: gpt-4
  temperature: 0.2
  max_tokens: 4096
  streaming: true

limits:
  max_chunk_lines: 400
  max_file_size_kb: 256
  max_files_per_review: 50
  context_lines: 3
```

## Review Rubric

### Dimensions (Weighted)

1. **Correctness** (weight: 10)
   - Logical bugs
   - Edge cases
   - Error handling
   - Type safety

2. **Security** (weight: 10)
   - Injection vulnerabilities
   - Unsafe dependencies
   - Secrets exposure
   - Auth bypass
   - Data validation

3. **Performance** (weight: 7)
   - Algorithmic complexity
   - N+1 queries
   - Memory leaks
   - Unnecessary allocations
   - Blocking operations

4. **Clarity** (weight: 6)
   - Naming conventions
   - Dead code
   - Comment quality
   - Function length
   - Cognitive complexity

5. **Maintainability** (weight: 8)
   - Modularity
   - Code duplication
   - Test coverage
   - Dependency coupling
   - Single responsibility

6. **Style** (weight: 4)
   - Formatting
   - Idioms
   - Consistency

## Severity Levels

- 🔴 **Critical**: Exploitable security flaw or data loss risk (exit code: 1)
- 🟠 **High**: Logic bug causing incorrect output or major performance issue (exit code: 1)
- 🟡 **Medium**: Maintainability concern or moderate performance issue
- 🔵 **Low**: Style or minor clarity improvement
- ⚪ **Info**: Optional improvement or suggestion

## Security Features

### Auto-Redaction Patterns
- AWS credentials
- API keys (`api_key=`, `api-key=`)
- Passwords
- Secrets
- Tokens
- Bearer tokens

### Path Restrictions
- **Allowed**: `${WORKSPACE_ROOT}/**`
- **Blocked**: `.git/`, `node_modules/`, `vendor/`, `.env*`

## System Prompt

```
You are an expert code reviewer with deep knowledge across multiple programming languages and frameworks.
Your role is to analyze code changes and provide constructive, actionable feedback.

Review Guidelines:
- Focus on the RUBRIC dimensions: correctness, security, performance, clarity, maintainability, and style
- Assign appropriate severity levels: critical, high, medium, low, info
- Provide specific line references and rationale for each finding
- Suggest concrete fixes when possible
- Be concise but thorough
- Acknowledge good practices when present
- Consider the broader context and architecture
```

## Output Format

```json
{
  "summary": {
    "overall_assessment": "string",
    "complexity_score": 0-100,
    "risk_level": "low|medium|high|critical"
  },
  "findings": [
    {
      "id": "unique-id",
      "severity": "critical|high|medium|low|info",
      "category": "correctness|security|performance|clarity|maintainability|style",
      "file": "path/to/file",
      "line": 42,
      "title": "Brief issue description",
      "description": "Detailed explanation",
      "recommendation": "How to fix",
      "code_snippet": "relevant code",
      "suggested_fix": "optional patch"
    }
  ],
  "metrics": {
    "files_changed": 0,
    "lines_added": 0,
    "lines_removed": 0,
    "test_coverage_impact": "estimated impact"
  },
  "questions": ["clarifying questions for the developer"]
}
```

## Integrations

### Linters
- **ESLint** (enabled, `.eslintrc`)
- **Pylint** (enabled)
- **golangci-lint** (enabled)

### Static Analysis
- **Semgrep** (enabled, auto rules)
- **Trivy** (enabled, vuln + secret scan)

## Hooks

### Pre-Review
- Validate git repo
- Check staged changes
- Run linters

### Post-Review
- Aggregate findings
- Deduplicate issues
- Sort by severity
- Generate summary

## Rate Limiting

- **Requests per minute**: 60
- **Burst size**: 10
- **Retry strategy**: Exponential backoff (1s → 10s max, 3 retries)

## Caching

- **Enabled**: Yes
- **TTL**: 3600 seconds (1 hour)
- **Key strategy**: Hash of diff
- **Invalidate on**: Config change, diff change

## Usage

```bash
# Review staged changes
/review

# Review with strict mode
/review --strict

# Output as JSON
/review --json

# Verbose mode
/review --verbose

# Disable telemetry
/review --no-upload
```

## Flags

- `strict_mode`: false (default)
- `auto_fix`: false
- `interactive`: true
- `verbose`: false
- `no_upload`: false
- `json_output`: false
- `markdown_output`: true

## Environment Variables

```bash
export COPILOT_TOKEN="your-github-copilot-token"
```

## Input Sources

- Git diff (staged)
- File context (surrounding code)
- Architecture overview

## Preprocessing

- Language detection
- Complexity metrics calculation
- Secret scanning

## Capabilities

- Diff analysis
- Multi-file support
- Patch generation
- Code analysis
