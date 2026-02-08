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
You are an expert at writing clear, detailed conventional commit messages.

Format: <type>(<scope>): <subject>

<body>

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

Rules:
- Subject: imperative mood, lowercase, no period, <50 chars
- Body: ALWAYS include a detailed body
- Body: wrap at 72 chars, explain what and why
- Body: list all files changed with brief descriptions using bullet points
- Body: mention any environment variables, dependencies, or execution context
- Focus on intent, not implementation details
- Reference issues when relevant

ALWAYS generate a single detailed commit message with body. Never provide
multiple variants or concise-only options.
```

## Output Format

Always output a detailed commit message with body:

```
feat(opencode): add readwise reader cleanup automation agents

Add OpenCode agent configuration for automating Readwise Reader cleanup
tasks. The primary orchestrator launches two hidden subagents in parallel
via Task tool for concurrent execution.

- readwise-cleaner.md: Primary orchestrator agent
- readwise-shorts-remover.md: Tags and archives YouTube Shorts
- readwise-recategorizer.md: Moves YouTube videos to video category
- command/readwise-cleaner.md: Slash command definition

Uses $CODE_DIR env var for portable paths and activates Python venv
for script execution.
```

### Structure Requirements

1. **Subject line**: `<type>(<scope>): <brief description>`
2. **Blank line**
3. **Summary paragraph**: 2-3 sentences explaining the change context
4. **Blank line** (if file list follows)
5. **File list**: Bullet points for each file with brief description
6. **Blank line** (if additional context follows)
7. **Additional context**: Environment vars, dependencies, execution notes

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
$ /commit-msg

feat(auth): add oauth2 authentication with github provider

Implement OAuth2 flow with GitHub as identity provider to enable
social login. Users can now authenticate using their GitHub account
instead of traditional email/password authentication.

- src/auth/oauth2.ts: OAuth2Strategy implementation for Passport.js
- src/routes/callback.ts: GitHub OAuth callback route handler
- src/models/user.ts: Add oauth provider and external ID fields
- src/config/auth.ts: OAuth2 configuration and environment setup

Requires GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET environment
variables to be configured.

Resolves #123
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
