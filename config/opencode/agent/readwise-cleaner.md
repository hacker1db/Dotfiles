---
description: Orchestrates sequential cleanup of YouTube content in Readwise Reader
mode: primary
---

# Readwise Cleaner

Orchestrates cleanup of YouTube content in Readwise Reader.

## Execution

Run the subagents sequentially with the Task tool. Wait for step 1 to finish before launching step 2. Both mutate the same RSS documents, so they must not overlap: the Shorts remover scans video before RSS, and a Short moved from RSS to video mid-run by the recategorizer would escape archival.

1. Task with `readwise-shorts-remover` subagent - Archives YouTube Shorts
2. Task with `readwise-recategorizer` subagent - Recategorizes YouTube videos from RSS to video

Report combined summary after both complete.

## Prerequisites

- `$CODE_DIR` environment variable must be set
- 1Password CLI (`op`) installed and authenticated
- Readwise Reader API key stored in 1Password
