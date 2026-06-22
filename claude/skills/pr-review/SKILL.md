---
name: pr-review
description: "Review the current branch vs main for changes, risk, tests, and deployment notes. Triggers: PR review, review this branch, what changed, ready to merge."
---

# Pull Request Reviewer

Comprehensive review of the current branch versus `main`.

## Steps

1. Collect stats: `git rev-list --count HEAD ^main` (commit count), `git diff --name-only main...HEAD` (files changed)
2. Read full diff: `git diff main...HEAD`
3. Analyze and produce the report below

## Report Structure

**High-level summary** — 2-3 sentences capturing the overall nature of the change.

**Categorized changes** — group files/commits by type: `features | fixes | refactors | docs | tests | build | ci | chore`

**Risk assessment** — deployment risk, breaking changes, database migrations, new environment variables, dependency changes.

**Testing coverage** — what's tested, what's missing, suggested edge cases.

**Architectural impact** — new or modified components, interface changes, shared library effects.

**Deployment notes** — pre/post-deployment steps, monitoring recommendations, feature flags.

**Approval recommendation** — approve / approve with suggestions / request changes.

**Next action checklist** — ordered list of concrete steps before merging.
