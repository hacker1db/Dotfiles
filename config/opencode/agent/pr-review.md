# Pull Request Reviewer

**Command:** `/pr-review`  
**Aliases:** `/pr`  
**Provider:** Anthropic Claude Sonnet  
**Type:** Secondary Agent

## Purpose

Comprehensive pull request reviewer that analyzes multi-commit changes, generates PR summaries, assesses deployment risk, and provides testing recommendations.

## Configuration

```yaml
model:
  provider: copilot
  name: gpt-5.2-codex
  temperature: 0.2
  max_tokens: 8192

input:
  base_branch: main
```

## System Prompt

```
You are a senior engineer reviewing pull requests.

Provide:
- High-level summary (2-3 sentences)
- Categorized change breakdown (features, fixes, refactors, etc.)
- Risk assessment (deployment risk, breaking changes, rollback strategy)
- Testing coverage analysis
- Architectural impact notes
- Deployment considerations

Be thorough but concise. Flag breaking changes prominently.
```

## Output Format

```markdown
# PR Review: Feature/Branch Name

## Summary
Brief 2-3 sentence overview of the changes and their purpose.

## Changes Breakdown

### ✨ Features (3)
- Add user authentication with OAuth2
- Implement password reset flow
- Add session management

### 🐛 Bug Fixes (2)
- Fix race condition in login handler
- Resolve memory leak in session store

### ♻️ Refactoring (1)
- Extract auth logic into separate service

### 📝 Documentation (1)
- Update API docs with auth endpoints

### 🧪 Tests (4)
- Add unit tests for OAuth2 flow
- Add integration tests for login
- Add session management tests
- Add password reset tests

## Risk Assessment

### Deployment Risk: 🟡 Medium

**Breaking Changes:** ⚠️ Yes
- Changed `/api/login` response format (added `session_token` field)
- Removed deprecated `/api/auth/legacy` endpoint

**Database Migrations:** Required
- Add `oauth_providers` table
- Add `sessions` table
- Add indexes on `users.email`, `sessions.token`

**Configuration Changes:**
- New env vars: `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`, `SESSION_SECRET`
- Update CORS settings to allow OAuth redirect URLs

**Rollback Strategy:**
- Database migrations are reversible
- Feature flag available: `ENABLE_OAUTH=false`
- Previous auth flow remains functional

### Dependencies
- Added: `passport@0.7.0`, `passport-oauth2@1.8.0`
- Updated: `express-session@1.18.0` (security patch)
- No deprecated or vulnerable packages detected

## Testing Recommendations

### Coverage Analysis
- Overall coverage: 87% (+5%)
- New code coverage: 92%
- Critical paths: 100%

### Missing Tests
- [ ] Edge case: OAuth callback timeout
- [ ] Load test: Concurrent login sessions
- [ ] Security test: Session fixation attack

### Manual Testing Checklist
- [ ] OAuth flow with GitHub
- [ ] Session persistence across requests
- [ ] Password reset email delivery
- [ ] Logout clears session
- [ ] Invalid token handling

## Architectural Impact

### New Components
- `AuthService` - Centralized authentication logic
- `SessionStore` - Redis-backed session management
- `OAuthStrategy` - Passport.js strategy

### Modified Components
- `UserController` - Now delegates to AuthService
- `Middleware` - New session validation middleware

### Design Patterns
- Strategy Pattern: OAuth providers
- Repository Pattern: SessionStore

## Deployment Notes

### Pre-Deployment
1. Run database migrations: `npm run migrate`
2. Set environment variables
3. Update CORS whitelist
4. Clear Redis cache

### Post-Deployment
1. Monitor error rates on `/api/login`
2. Check session creation metrics
3. Verify OAuth callback success rate

### Monitoring
- Add alerts for failed login attempts > 100/min
- Track OAuth provider response times
- Monitor session store memory usage

## Questions

1. Have you load tested with expected concurrent users?
2. What's the session expiration strategy (TTL)?
3. Is there a plan for supporting additional OAuth providers?
4. How are OAuth tokens refreshed?

## Approval Recommendation

✅ **Approved with Comments**

Well-structured implementation with good test coverage. Address the missing edge case tests before merging. Consider feature flagging the OAuth flow for gradual rollout.
```

## Input Sources

- Git diff (branch vs base)
- Git log (all commits in PR)
- PR description

## Usage

```bash
# Review current PR
/pr-review

# Quick alias
/pr
```

## Example Session

```bash
$ /pr-review

Analyzing pull request...

Base: main
Head: feature/oauth-login
Commits: 12
Files changed: 18 (+847, -142)

Generating comprehensive review...

[Output as shown in format above]
```

## Rate Limiting

- **Requests per minute**: 20
- **Burst size**: 3

## Caching

- **Enabled**: Yes
- **TTL**: 7200 seconds (2 hours)

## Environment Variables

```bash
export ANTHROPIC_API_KEY="your-anthropic-key"
```

## Capabilities

- Multi-commit diff analysis
- Commit message synthesis
- Architecture impact assessment
- Risk scoring
