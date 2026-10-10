---
name: pr-review
description: "Review an identified pull request or Git branch against its actual target branch, covering changes, risk, tests, architecture, and deployment. Use for PR review, branch review, or merge readiness of a specified change. Use review for staged changes or standalone code patches that are not identified as pull request reviews."
---

# Pull Request Reviewer

Review the selected pull request or branch against its actual target. Respect a base supplied by the user. Do not assume `main`, and do not treat a generic "what changed" as a request for this review.

## Steps

1. Resolve the change and base. For a supplied PR, use its verified base and head metadata through an available repository connector or CLI. For a local branch, inspect repository instructions, upstream metadata, and local remote HEAD information. A tracking branch may be the feature branch itself, so do not treat it as a merge target without supporting evidence. Use `git symbolic-ref --quiet refs/remotes/origin/HEAD` only when origin exists and its default branch is the intended target. Ask for the target if local evidence leaves it ambiguous.
2. Verify the selected base and head refs resolve locally, or use the supplied PR diff if local refs are unavailable. Do not silently substitute another base or fetch unrelated repositories. State evidence limits when only a supplied patch is available.
3. For local refs, compute the merge base with `git merge-base <base> <head>`, then inspect `git rev-list --count <head> ^<base>` and `git diff --name-only <base>...<head>`. Safely pass verified refs as arguments.
4. Read `git diff <base>...<head>` and relevant surrounding code. Record the base, head, and comparison used so the review can be reproduced. Do not include uncommitted files in a branch comparison unless requested.
5. Produce the report below. Report checks actually performed and clearly label suggested tests. This review does not itself authorize merging or publishing comments.

## Report Structure

**High-level summary** — 2-3 sentences capturing the overall nature of the change.

**Categorized changes** — group files/commits by type: `features | fixes | refactors | docs | tests | build | ci | chore`

**Risk assessment** — deployment risk, breaking changes, database migrations, new environment variables, dependency changes.

**Testing coverage** — what's tested, what's missing, suggested edge cases.

**Architectural impact** — new or modified components, interface changes, shared library effects.

**Deployment notes** — pre/post-deployment steps, monitoring recommendations, feature flags.

**Approval recommendation** — approve / approve with suggestions / request changes.

**Next action checklist** — ordered list of concrete steps before merging.
