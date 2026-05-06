---
name: readwise-cleaner
description: Orchestrates parallel cleanup of YouTube content in Readwise Reader by running the shorts remover and recategorizer scripts simultaneously
---

Orchestrates parallel cleanup of YouTube content in Readwise Reader.

## Execution

Run both scripts in parallel using two simultaneous Bash tool calls:

1. `~/.dotfiles/bin/remove-shorts.sh` — finds YouTube Shorts, tags with `youtube-shorts`, archives them
2. `~/.dotfiles/bin/recategorize.sh` — moves YouTube videos from RSS → video category

Report combined summary when both complete:
- Documents scanned
- Shorts found and archived
- Videos recategorized
- Any errors from either script

## Prerequisites

- `readwise` CLI installed and authenticated (`readwise login`)
- `jq` installed
