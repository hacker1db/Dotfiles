---
description: Azure DevOps CLI operations — wiki, work items, boards, pipelines, repos, and PRs via `az` CLI
---
Azure DevOps CLI operations covering wiki, boards, pipelines, and repos.

## Prerequisites

```bash
# Install extension
az extension add --name azure-devops

# Configure defaults (run once per project)
az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>

# Authenticate
az login
# Or with PAT
az devops login --organization https://dev.azure.com/<org>
```

---

## Wiki

/open-wiki <wiki_path | local_file>
- If argument starts with `/`, treat as wiki path and resolve to local file. If found, open in neovim. If not found, fetch content via CLI and print.
- If argument does not start with `/`, treat as local file path (relative to CWD) and open directly in neovim.
- Examples:
  - `open-wiki /Security Best Practices/Cloud Security/Azure: Patterns & Practices`
  - `open-wiki Security-Best-Practices/Cloud-Security/Azure%3A-Patterns-&-Practices.md`

/copy-wiki-url <wiki_path>
- Copies the remote URL of the wiki page to clipboard.
- Command: `az devops wiki page show --wiki DevSecOps.wiki --path "<wiki_path>" --query page.remoteUrl -o tsv | pbcopy`
- Example: `copy-wiki-url /Security Best Practices/Cloud Security/Azure: Patterns & Practices`

Wiki notes:
- Local wiki files are at `~/Developer/appsec/DevSecOps.wiki`
- Colons in local filenames appear as `%3A`; ampersand remains `&`
- Enumerate pages when path is uncertain: `az devops wiki page show --wiki DevSecOps.wiki --path "/" --recursion-level Full`
- List all wikis: `az devops wiki list`

---

## Work Items / Boards

```bash
# Show a work item
az boards work-item show --id <id>

# Create a work item
az boards work-item create --title "<title>" --type "Task" --assigned-to "<email>"

# Update a work item
az boards work-item update --id <id> --state "Active" --assigned-to "<email>"

# Query with WIQL
az boards query --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.AssignedTo] = @me"

# Add a relation between work items
az boards work-item relation add --id <id> --relation-type "System.LinkTypes.Hierarchy-Reverse" --target-id <parent-id>
```

---

## Pipelines

```bash
# List pipelines
az pipelines list --output table

# Show pipeline details
az pipelines show --name "<pipeline-name>"

# Run (queue) a pipeline
az pipelines run --name "<pipeline-name>" --branch main

# List runs for a pipeline
az pipelines runs list --pipeline-name "<pipeline-name>" --output table

# Show a specific run
az pipelines runs show --id <run-id>

# List builds
az pipelines build list --output table

# Show a build
az pipelines build show --id <build-id>

# Queue a build
az pipelines build queue --definition-name "<pipeline-name>"

# Cancel a running build
az pipelines build cancel --id <build-id>
```

---

## Repos / PRs

```bash
# List repos in project
az repos list --output table

# Show repo details
az repos show --repository <repo-name>

# List refs (branches/tags)
az repos ref list --repository <repo-name> --output table

# Create a PR
az repos pr create --repository <repo-name> --source-branch <branch> --target-branch main --title "<title>" --description "<body>"

# List PRs
az repos pr list --repository <repo-name> --output table

# Show a PR
az repos pr show --id <pr-id>

# Update a PR (set auto-complete, add reviewers, etc.)
az repos pr update --id <pr-id> --auto-complete true

# Vote on a PR (approve/reject/reset)
az repos pr set-vote --id <pr-id> --vote approve
```

---

## Projects

```bash
# List all projects in org
az devops project list --output table

# Show project details
az devops project show --project <project-name>
```

---

## Output Formats

Append `--output table` (human), `--output json` (machine), or `--output tsv` (pipeable) to any command.

---

## Advanced: REST API via invoke

```bash
# Call any DevOps REST endpoint directly
az devops invoke \
  --area wit \
  --resource workitems \
  --route-parameters project=<project> id=<id> \
  --api-version 7.1 \
  --output json
```

See: https://docs.microsoft.com/en-us/rest/api/azure/devops/
