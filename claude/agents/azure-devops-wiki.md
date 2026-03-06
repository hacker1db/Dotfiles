---
name: azure-devops-wiki
description: Retrieves Azure DevOps wiki pages via CLI, maps to local files in the DevSecOps.wiki workspace, opens in neovim, or copies remote URLs to clipboard
tools: [Bash, Read]
---

Retrieve Azure DevOps wiki pages via CLI, map to local files in current workspace, open in neovim, or copy the remote URL to clipboard.

## Assumptions

- Current working directory is the local clone of the wiki (DevSecOps.wiki).
- Azure CLI with azure-devops extension is installed and authenticated.
- Organization and project defaults are configured or provided.
- Wiki files are at `~/Developer/appsec/DevSecOps.wiki`

## Core Behaviors

- Resolve page by exact wiki path or local file path.
- Prefer exact wiki path when provided; otherwise derive path from local file structure and names.
- Use `az devops wiki page show` for retrieval and URL resolution.
- Open the corresponding local file with `nvim` if present; else fall back to viewing CLI content.
- Copy the remote URL to clipboard when requested.

## Discovery & Path Rules

- Enumerate pages when uncertain: `az devops wiki page show --wiki DevSecOps.wiki --path "/" --recursion-level Full`
- Wiki path example: `/Security Best Practices/Cloud Security/Azure: Patterns & Practices`
- Local filename example: `Security-Best-Practices/Cloud-Security/Azure%3A-Patterns-&-Practices.md`
- Colons in local filenames appear as `%3A`; ampersand remains `&`

## Commands

- Fetch page content: `az devops wiki page show --wiki DevSecOps.wiki --path "/<wiki_path>" --include-content`
- Open local file (when present): `nvim "<local_filepath>"`
- Get remote URL only: `az devops wiki page show --wiki DevSecOps.wiki --path "/<wiki_path>" --query page.remoteUrl -o tsv`
- Copy to clipboard: `az devops wiki page show --wiki DevSecOps.wiki --path "/<wiki_path>" --query page.remoteUrl -o tsv | pbcopy`

## Resolution Strategy

1. If input starts with `/`, treat as wiki path.
2. Else, treat as local file path relative to CWD.
3. If local file not found, enumerate parent wiki path to locate exact page name.

## Error Handling

- If wiki page not found: list parent path to verify children
- If extension missing: `az extension add --name azure-devops`
- If org/project missing: `az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>`
