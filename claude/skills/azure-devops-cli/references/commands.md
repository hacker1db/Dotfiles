# Azure DevOps CLI — Command Reference

## Configure Defaults

```bash
az devops configure --defaults organization=https://dev.azure.com/ORG project=PROJECT
az devops configure --list
```

## Wiki

```bash
# List wikis
az devops wiki list [--org URL] [--project PROJECT]

# Show a page (fetch full content)
az devops wiki page show \
  --org https://dev.azure.com/ORG \
  --project PROJECT \
  --wiki WIKI_IDENTIFIER \
  --path '/Page/Path' \
  --include-content \
  --query 'content' -o tsv

# Create a page
az devops wiki page create \
  --org https://dev.azure.com/ORG \
  --project PROJECT \
  --wiki WIKI \
  --path '/Page/Path' \
  --content @file.md \
  --encoding utf-8

# Update a page (requires --version ETag from show)
az devops wiki page update \
  --org https://dev.azure.com/ORG \
  --project PROJECT \
  --wiki WIKI \
  --path '/Page/Path' \
  --content @file.md \
  --version <ETag>

# Delete a page
az devops wiki page delete --path '/Page' --yes
```

### Wiki Filename Tip

Page paths with colons become `%3A` in the local git clone:
- ADO path: `/Runbooks/Server: Production`
- Local file: `Runbooks/Server%3A Production.md`

## Work Items

```bash
# Create
az boards work-item create --title "…" --type Bug --project PROJECT \
  --assigned-to "user@org.com" --description "…"

# Show
az boards work-item show --id 12345

# Update
az boards work-item update --id 12345 \
  --state Active --assigned-to "user@org.com"

# Query
az boards query --wiql "SELECT [Id],[Title] FROM WorkItems WHERE [State]='Active'"
```

## Boards (Iterations & Areas)

```bash
az boards iteration project list --project PROJECT --depth 3
az boards iteration project show --path '\Project\Sprint 1'
az boards area project list --project PROJECT
```

## Pipelines

```bash
az pipelines list [--project PROJECT] [--repository REPO]
az pipelines show --name pipeline-name
az pipelines run --name pipeline-name [--branch main] [--variables key=val]
az pipelines variable-group list --project PROJECT
az pipelines variable-group show --id 1
```

## Repos & PRs

```bash
# Repos
az repos list --project PROJECT
az repos show --name REPO --project PROJECT

# Create PR
az repos pr create \
  --title "…" --description "…" \
  --source-branch feature/my-branch \
  --target-branch main \
  --draft

# List PRs
az repos pr list [--status active|abandoned|completed|all]

# Show PR
az repos pr show --id 42

# Update / merge PR
az repos pr update --id 42 --status completed --merge-strategy squash

# Set vote
az repos pr set-vote --id 42 --vote approve
```

## Projects

```bash
az devops project list
az devops project show --project PROJECT
az devops project create --name "New Project" --visibility private
```
