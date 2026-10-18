---
description: Comprehensive gh CLI reference for GitHub operations — PRs, issues, Actions, search, and REST API calls
---
Use this skill when performing any GitHub operation via the command line: creating or reviewing PRs, managing issues, monitoring Actions runs, searching repos, or making direct API calls.

## Auth Check

Before any operation, verify authentication:
```
gh auth status
```
If unauthenticated: `gh auth login`

## Pull Request Workflow

```bash
# Create PR (infers title/body from commits)
gh pr create --fill
gh pr create --title "feat: add timeout" --body "Closes #42" --draft
gh pr create --base main --head feature-branch --assignee @me

# List PRs
gh pr list
gh pr list --state open --label bug --json number,title,author --jq '.[] | "\(.number) \(.title)"'

# View PR
gh pr view 123
gh pr view 123 --web
gh pr view --json title,body,reviews,checks

# Review
gh pr review 123 --approve
gh pr review 123 --request-changes --body "Needs tests"
gh pr review 123 --comment --body "LGTM on the approach"

# Check CI status
gh pr checks 123
gh pr checks 123 --watch

# Merge
gh pr merge 123 --squash --delete-branch
gh pr merge 123 --merge --auto

# Other operations
gh pr checkout 123          # check out branch locally
gh pr diff 123              # view diff
gh pr edit 123 --add-label "needs-review" --add-assignee octocat
gh pr ready 123             # mark draft as ready
gh pr update-branch 123     # update branch from base
gh pr close 123
gh pr reopen 123
```

## Issue Workflow

```bash
# Create
gh issue create --title "Bug: crash on login" --body "Steps to reproduce..." --label bug
gh issue create --assignee @me --milestone "v2.0"

# List
gh issue list
gh issue list --assignee @me --state open
gh issue list --label "bug,priority:high" --json number,title --jq '.[] | .title'

# View & comment
gh issue view 42
gh issue view 42 --web
gh issue comment 42 --body "Looking into this now"

# Manage
gh issue edit 42 --add-label "confirmed" --remove-label "needs-triage"
gh issue close 42 --comment "Fixed in #123"
gh issue reopen 42
gh issue develop 42 --branch fix/issue-42   # create linked branch
```

## Repository Operations

```bash
gh repo clone owner/repo
gh repo clone owner/repo -- --depth=1       # shallow clone
gh repo fork owner/repo --clone            # fork and clone
gh repo view owner/repo
gh repo view owner/repo --web
gh repo create my-new-repo --public --source=. --push
gh repo list myorg --limit 50
```

## Actions: Runs & Workflows

```bash
# Runs
gh run list
gh run list --workflow ci.yml --branch main --limit 10
gh run view 12345678
gh run view 12345678 --log                  # full logs
gh run view 12345678 --log-failed           # only failed step logs
gh run watch 12345678                       # stream live progress
gh run rerun 12345678 --failed-only
gh run download 12345678 --name artifact-name --dir ./artifacts
gh run cancel 12345678

# Workflows
gh workflow list
gh workflow view ci.yml
gh workflow run deploy.yml --field environment=staging
gh workflow enable ci.yml
gh workflow disable ci.yml
```

## Search

```bash
gh search repos "dotfiles stars:>500" --language shell --limit 20
gh search prs "fix timeout" --repo owner/repo --state open
gh search issues "memory leak" --label bug --state open --json number,title,url
gh search code "TODO" --repo owner/repo --extension ts
gh search commits "refactor auth" --author octocat
```

## REST API with `gh api`

```bash
# GET request
gh api repos/{owner}/{repo}/releases/latest
gh api /user                                # authenticated user

# POST/PATCH with fields
gh api repos/{owner}/{repo}/issues --method POST \
  -f title="Bug report" \
  -f body="Details..." \
  -f "labels[]=bug"

# PATCH existing resource
gh api repos/{owner}/{repo}/issues/42 --method PATCH \
  -f state=closed

# Filter output with --jq
gh api repos/{owner}/{repo}/pulls --jq '.[].title'
gh api /user/repos --jq '.[] | select(.fork==false) | .full_name'

# Paginate all results
gh api --paginate /repos/{owner}/{repo}/issues --jq '.[].number'

# GraphQL
gh api graphql -f query='{ viewer { login } }'
```

## Useful Flags (global)

| Flag | Purpose |
|------|---------|
| `-R owner/repo` | Target a different repo |
| `--json field1,field2` | Output specific fields as JSON |
| `--jq <expr>` | Filter JSON output with jq expression |
| `--web` | Open result in browser |
| `--limit N` | Cap result count |

## Tips

```bash
# Chain: get PR number then view checks
gh pr list --json number,headRefName --jq '.[] | select(.headRefName=="my-branch") | .number' \
  | xargs gh pr checks

# Cross-repo operation
gh pr list -R org/other-repo --state merged --limit 5

# Pretty-print any JSON response
gh api /repos/{owner}/{repo} | jq .

# List open PRs assigned to me across repos
gh search prs --assignee @me --state open
```
