---
description: Comprehensive pull request review of current branch vs main
---
Summarize current branch vs base (main) including commit count via !`git rev-list --count HEAD ^main`, files changed via !`git diff --name-only main...HEAD`.
Provide:
- High-level summary (2-3 sentences)
- Categorized changes (features|fixes|refactors|docs|tests|build|ci|chore)
- Risk assessment (deployment risk, breaking changes, migrations, env vars)
- Testing coverage recommendations (missing edge cases)
- Architectural impact (new/modified components)
- Deployment notes (pre/post steps, monitoring)
Finish with approval recommendation and next action checklist.
