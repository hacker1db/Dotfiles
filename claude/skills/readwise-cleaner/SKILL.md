---
name: readwise-cleaner
description: "Clean YouTube content in Readwise Reader. Triggers: clean Readwise, archive shorts, YouTube Shorts, recategorize videos."
---

# Readwise Cleaner

Run both Readwise cleanup scripts in parallel to organize YouTube content in Readwise Reader.

## Readwise Plugin

When running on an OpenAI model with the Readwise plugin available, use the plugin before local scripts for Reader operations:
- `_reader_search_documents` or `_reader_list_documents` to find YouTube Shorts and YouTube documents
- `_reader_add_tags_to_document` to tag Shorts with `youtube-shorts`
- `_reader_move_documents` to archive Shorts in batches of up to 50
- `_reader_bulk_edit_document_metadata` for supported metadata changes

Use the scripts below as fallback when the plugin is unavailable or when a workflow needs script-only logic.

## Scripts

```
~/.dotfiles/bin/remove-shorts.sh
~/.dotfiles/bin/recategorize.sh
```

## Steps

Launch **both** scripts simultaneously (not sequentially) using two parallel Bash tool calls:

- `~/.dotfiles/bin/remove-shorts.sh` — finds YouTube Shorts, tags with `youtube-shorts`, archives them
- `~/.dotfiles/bin/recategorize.sh` — moves YouTube videos from RSS → video category

Report combined summary when both complete:
- Documents scanned
- Shorts found and archived
- Videos recategorized
- Any errors from either script

## Prerequisites

- `readwise` CLI installed and authenticated (`readwise login`)
- `jq` installed
