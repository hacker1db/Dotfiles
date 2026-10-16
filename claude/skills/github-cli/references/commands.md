# GitHub CLI — Command Reference

## Pull Requests

```bash
gh pr create --title "…" --body "…" --base main --draft
gh pr list [--state open|closed|merged] [--author @me] [--label bug]
gh pr view [<number>] [--web]
gh pr checkout <number>
gh pr merge <number> [--squash|--rebase|--merge] [--delete-branch]
gh pr review <number> [--approve|--request-changes|--comment] [-b "body"]
gh pr diff <number>
gh pr status                           # PRs involving you
gh pr close <number>
gh pr reopen <number>
gh pr edit <number> --title "…" --body "…" --add-label bug
gh pr checks <number>                  # CI status
```

## Issues

```bash
gh issue create --title "…" --body "…" --label bug --assignee @me
gh issue list [--state open|closed|all] [--assignee @me] [--label "…"]
gh issue view <number> [--web]
gh issue close <number>
gh issue reopen <number>
gh issue comment <number> --body "…"
gh issue edit <number> --title "…" --add-label "…" --remove-assignee "…"
gh issue pin <number>
```

## Repos

```bash
gh repo create [name] [--public|--private] [--template owner/repo]
gh repo clone owner/repo [dir]
gh repo fork owner/repo [--clone]
gh repo view [owner/repo] [--web]
gh repo list [owner] [--limit 50]
gh repo archive owner/repo
gh repo delete owner/repo --confirm
gh repo set-default owner/repo
```

## GitHub Actions

```bash
gh run list [--workflow file.yml] [--branch main]
gh run view <id> [--log] [--web]
gh run watch <id>
gh run rerun <id>
gh run cancel <id>
gh workflow list
gh workflow run <workflow> [--ref branch] [-f key=value]
gh workflow enable/disable <workflow>
```

## Search

```bash
gh search repos "query" [--language go] [--stars ">100"]
gh search issues "query" [--repo owner/repo] [--state open]
gh search prs "query" [--author login]
gh search code "query" [--repo owner/repo] [--language js]
gh search commits "query" [--repo owner/repo]
```

## REST API

```bash
# GET
gh api repos/{owner}/{repo}/releases/latest
gh api orgs/{org}/members --paginate

# POST
gh api repos/{owner}/{repo}/issues \
  --method POST \
  -f title="Bug report" -f body="Details…"

# PATCH
gh api repos/{owner}/{repo}/issues/1 \
  --method PATCH -f state=closed

# With jq filter
gh api graphql -f query='{ viewer { login } }' --jq '.data.viewer.login'
```

## Auth

```bash
gh auth login [--github.com|--hostname enterprise.example.com]
gh auth status
gh auth token                          # print current token
gh auth logout
```

## Useful Patterns

```bash
# List my open PRs across all repos
gh pr list --author @me --state open -R org/repo

# Watch a workflow run live
gh run watch $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')

# Bulk close stale issues
gh issue list --label stale --json number --jq '.[].number' | \
  xargs -I{} gh issue close {}

# Get PR checks and filter failures
gh pr checks --json name,state | jq '[.[] | select(.state != "SUCCESS")]'
```
