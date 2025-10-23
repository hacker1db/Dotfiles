# Commit Message Assistant

**Command:** `/commit-msg`  
**Aliases:** `/commit`, `/cm`  
**Provider:** GitHub Copilot (GPT-5)  
**Type:** Secondary Agent

## Purpose

Analyzes staged changes and generates meaningful commit messages following Conventional Commits specification.

## Configuration

```yaml
model:
  provider: copilot
  name: gpt-5-commit
  temperature: 0.3
  max_tokens: 1024
```

## Conventional Commit Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semi colons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `build`: Build system or external dependencies
- `ci`: CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

### Rules

- **Subject**: Imperative mood, lowercase, no period, <50 chars
- **Body**: Wrap at 72 chars, explain what and why (not how)
- **Footer**: Issue references, breaking changes

## System Prompt

```
You are an expert at writing clear, conventional commit messages.

Format: <type>(<scope>): <subject>

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

Rules:
- Subject: imperative mood, lowercase, no period, <50 chars
- Body: wrap at 72 chars, explain what and why
- Focus on intent, not implementation details
- Reference issues when relevant

Provide 3 variants: concise, detailed, and with body.
```

## Output Format

### Variant 1: Concise
```
feat(auth): add oauth2 support
```

### Variant 2: Detailed
```
feat(auth): add oauth2 authentication with github provider
```

### Variant 3: With Body
```
feat(auth): add oauth2 authentication

Implement OAuth2 flow with GitHub as identity provider to enable
social login. Users can now authenticate using their GitHub account
instead of email/password.

Resolves #123
```

## Input Sources

- Git diff (staged)
- Git log (recent 10 commits for style reference)
- Branch name (for context)

## Usage

```bash
# Generate commit message variants
/commit-msg

# Quick alias
/commit

# Short form
/cm
```

## Example Session

```bash
$ /commit

Analyzing staged changes...

Branch: feature/oauth-login
Files changed: 3 (+142, -8)

Suggested commit messages:

1. Concise:
   feat(auth): add oauth2 support

2. Detailed:
   feat(auth): add oauth2 authentication with github provider

3. With Body:
   feat(auth): add oauth2 authentication
   
   Implement OAuth2 flow with GitHub as identity provider to enable
   social login. Users can now authenticate using their GitHub account.
   
   - Add OAuth2Strategy for Passport.js
   - Create callback route for GitHub
   - Update user model with oauth fields
   
   Resolves #123

Select variant (1/2/3) or edit:
```

## Rate Limiting

- **Requests per minute**: 120
- **Burst size**: 20

## Caching

- **Enabled**: Yes
- **TTL**: 300 seconds (5 minutes)

## Environment Variables

```bash
export COPILOT_TOKEN="your-github-copilot-token"
```

## Capabilities

- Diff analysis
- Commit history learning
- Branch context awareness
