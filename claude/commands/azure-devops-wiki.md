---
description: Azure DevOps wiki operations — open pages in neovim or copy remote URLs to clipboard
---
Azure DevOps Wiki operations for the DevSecOps.wiki.

/open-wiki <wiki_path | local_file>
- If argument starts with `/`, treat as wiki path and attempt to resolve the local file that corresponds. If found, open in neovim. If not found, fetch content via CLI and print.
- If argument does not start with `/`, treat as a local file path (relative to CWD) and open directly in neovim.
- Examples:
  - `open-wiki /Security Best Practices/Cloud Security/Azure: Patterns & Practices`
  - `open-wiki Security-Best-Practices/Cloud-Security/Azure%3A-Patterns-&-Practices.md`

/copy-wiki-url <wiki_path>
- Copies the remote URL of the wiki page to clipboard.
- Command: `az devops wiki page show --wiki DevSecOps.wiki --path "<wiki_path>" --query page.remoteUrl -o tsv | pbcopy`
- Example: `copy-wiki-url /Security Best Practices/Cloud Security/Azure: Patterns & Practices`

Notes:
- Ensure `azure-devops` CLI extension is installed: `az extension add --name azure-devops`
- Ensure organization and project defaults are configured: `az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>`
- Local filenames may encode colon as `%3A`. Ampersand remains `&`.
- Use enumeration if paths are uncertain: `az devops wiki page show --wiki DevSecOps.wiki --path "/" --recursion-level Full`
- Wiki files are at `~/Developer/appsec/DevSecOps.wiki`
