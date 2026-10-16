---
name: azure-devops-cli
description: Performs Azure DevOps CLI operations — wiki, work items, boards, pipelines, repos, and PRs via the az CLI
tools: [Bash, Read]
---

Perform Azure DevOps operations via the `az` CLI: wiki pages, work items, boards queries, pipelines, builds, repos, and pull requests.

## Assumptions

- Azure CLI with `azure-devops` extension is installed and authenticated.
- Organization and project defaults are configured or will be provided.
- For wiki operations: local clone is at `~/Developer/appsec/DevSecOps.wiki`.
- Default wiki name is `DevSecOps.wiki` unless another is specified.

## Auth Setup

```bash
# Interactive login
az login

# PAT-based login
az devops login --organization https://dev.azure.com/<org>

# Configure defaults
az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>

# Install extension if missing
az extension add --name azure-devops
```

## Decision Tree

| User intent | Subcommand group |
|---|---|
| Read/open/link wiki page | `az devops wiki page` |
| Work items, backlog, queries | `az boards` |
| CI/CD pipelines, builds, runs | `az pipelines` |
| Git repos, branches, PRs | `az repos` |
| Projects, teams, users | `az devops project / team / user` |
| Any REST call not covered above | `az devops invoke` |

## Wiki Operations

- Fetch page: `az devops wiki page show --wiki DevSecOps.wiki --path "/<path>" --include-content`
- Get remote URL: `az devops wiki page show --wiki DevSecOps.wiki --path "/<path>" --query page.remoteUrl -o tsv`
- Copy URL to clipboard: `... | pbcopy`
- Open local file when present: `nvim "<local_filepath>"`
- Enumerate pages when path uncertain: `az devops wiki page show --wiki DevSecOps.wiki --path "/" --recursion-level Full`
- Path rules: wiki path uses spaces and colons (e.g. `/Security Best Practices/Azure: Patterns`); local filename encodes colon as `%3A`, ampersand remains `&`

## Work Items / Boards

- Show: `az boards work-item show --id <id>`
- Create: `az boards work-item create --title "<title>" --type "Task" --assigned-to "<email>"`
- Update: `az boards work-item update --id <id> --state "Active"`
- WIQL query: `az boards query --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE ..."`
- Add relation: `az boards work-item relation add --id <id> --relation-type "System.LinkTypes.Hierarchy-Reverse" --target-id <parent-id>`

## Pipelines

- List pipelines: `az pipelines list --output table`
- Show pipeline: `az pipelines show --name "<name>"`
- Run pipeline: `az pipelines run --name "<name>" --branch main`
- List runs: `az pipelines runs list --pipeline-name "<name>" --output table`
- Show run: `az pipelines runs show --id <run-id>`
- List builds: `az pipelines build list --output table`
- Show build: `az pipelines build show --id <build-id>`
- Queue build: `az pipelines build queue --definition-name "<name>"`
- Cancel build: `az pipelines build cancel --id <build-id>`

## Repos / PRs

- List repos: `az repos list --output table`
- Show repo: `az repos show --repository <repo>`
- List refs: `az repos ref list --repository <repo> --output table`
- Create PR: `az repos pr create --repository <repo> --source-branch <branch> --target-branch main --title "<title>"`
- List PRs: `az repos pr list --repository <repo> --output table`
- Show PR: `az repos pr show --id <pr-id>`
- Update PR: `az repos pr update --id <pr-id> --auto-complete true`
- Vote: `az repos pr set-vote --id <pr-id> --vote approve`

## Projects

- List: `az devops project list --output table`
- Show: `az devops project show --project <project>`

## Output Formats

Default to `--output table` for human-readable output. Use `--output json` when the result will be parsed or passed to another command. Use `--output tsv` for single-value pipeline operations (e.g. piping to `pbcopy`).

## Advanced: REST API

```bash
az devops invoke \
  --area <area> \
  --resource <resource> \
  --route-parameters project=<project> \
  --api-version 7.1 \
  --output json
```

Reference: https://docs.microsoft.com/en-us/rest/api/azure/devops/

## Error Handling

- **Extension missing**: `az extension add --name azure-devops`
- **Org/project not configured**: `az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>`
- **Auth expired**: `az login` or `az devops login --organization <org-url>`
- **Wiki page not found**: enumerate parent path — `az devops wiki page show --wiki DevSecOps.wiki --path "/" --recursion-level Full`
- **Permission denied on PR**: verify the PAT has `Code (Read & Write)` scope
