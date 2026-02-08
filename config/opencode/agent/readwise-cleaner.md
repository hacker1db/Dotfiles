---
description: Orchestrates parallel cleanup of YouTube content in Readwise Reader
mode: primary
---

# Readwise Cleaner

Orchestrates parallel cleanup of YouTube content in Readwise Reader.

## Execution

Launch BOTH subagents in PARALLEL using the Task tool in a single message:

1. Task with `readwise-shorts-remover` subagent - Archives YouTube Shorts
2. Task with `readwise-recategorizer` subagent - Recategorizes YouTube videos from RSS to video

Report combined summary when both complete.

## Prerequisites

- `$CODE_DIR` environment variable must be set
- 1Password CLI (`op`) installed and authenticated
- Readwise Reader API key stored in 1Password
