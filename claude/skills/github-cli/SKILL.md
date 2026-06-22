---
name: github-cli
description: "Reference for GitHub CLI workflows. Triggers: gh pr, gh issue, create PR, GitHub CLI, gh repo, gh api."
---

# GitHub CLI Reference

Complete reference for the `gh` CLI covering PRs, issues, repos, Actions, and the REST API.

## Global Flags

| Flag | Purpose |
|------|---------|
| `-R owner/repo` | target a specific repo |
| `--json fields` | output as JSON |
| `--jq expression` | filter JSON output |
| `--web` | open in browser |
| `--limit N` | cap results |

## Command Groups

- **PRs** — create, list, view, checkout, merge, review, diff
- **Issues** — create, list, view, close, reopen, comment, assign, label
- **Repos** — create, clone, fork, view, list, archive
- **Actions** — run list/view/watch, workflow run/enable/disable
- **Search** — search repos, issues, PRs, code, commits
- **REST API** — `gh api` for any GitHub API endpoint
- **Auth** — `gh auth login/logout/status/token`
- **Gist** — create, list, view, edit, delete

See `references/commands.md` for full syntax, flags, and common patterns for each group.
