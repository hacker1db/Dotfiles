---
name: azure-devops-cli
description: "Comprehensive reference for the Azure DevOps CLI (az devops). Use this skill whenever the user wants to interact with Azure DevOps — wikis, work items, boards, pipelines, repos, PRs, or projects. Triggers on 'az devops', 'ADO cli', 'azure devops wiki', 'work item', 'ado pipeline', 'devops board', 'create wiki page', 'ado pr'."
---

# Azure DevOps CLI Reference

Complete reference for `az devops` and related `az` subcommands covering wikis, work items, pipelines, repos, and projects.

## Key Paths

- **Local wiki**: `~/Developer/appsec/DevSecOps.wiki`
- **Wiki filenames**: colons in page names appear as `%3A` in filesystem paths

## Command Groups

- **Wiki** — page show/create/update/delete, wiki list/create
- **Work Items** — create, show, update, delete, query, relation add/remove
- **Boards** — iteration list/show, area list/show
- **Pipelines** — list, show, run, variable-group list/show
- **Repos** — list, show; PR create/list/show/update/merge/set-vote
- **Projects** — list, show, create
- **Config** — `az devops configure --defaults organization= project=`

## Global Tips

```bash
# Set defaults to avoid repeating --org and --project
az devops configure --defaults organization=https://dev.azure.com/ORG project=PROJECT

# Output formats
--output table|json|tsv|yaml
--query '<jmespath>'
```

See `references/commands.md` for full syntax and common patterns.
