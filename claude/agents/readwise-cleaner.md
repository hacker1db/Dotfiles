---
name: readwise-cleaner
description: Orchestrates cleanup of YouTube content in Readwise Reader by running the shorts remover to completion, then the recategorizer
---

Orchestrates cleanup of YouTube content in Readwise Reader.

## Execution

Run the scripts sequentially, in this order. Do not start step 2 until step 1 has exited. Both mutate the same RSS documents, so they must not overlap: the Shorts remover scans video before RSS, and a Short moved from RSS to video mid-run by the recategorizer would escape archival.

1. `~/.dotfiles/bin/remove-shorts.sh` — finds YouTube Shorts, tags with `youtube-shorts`, archives them
2. `~/.dotfiles/bin/recategorize.sh` — moves YouTube videos from RSS → video category

Report combined summary after both complete:
- Documents scanned
- Shorts found and archived
- Videos recategorized
- Any errors from either script

## Prerequisites

- `readwise` CLI installed and authenticated (`readwise login`)
- `jq` installed
