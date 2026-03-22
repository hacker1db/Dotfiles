---
name: readwise-cleaner
description: "Clean up YouTube content in Readwise Reader by running the shorts archiver and video recategorizer in parallel. Use this skill when the user wants to clean up Readwise, archive YouTube Shorts, recategorize YouTube videos, organize their reading queue, or run the Readwise cleanup scripts. Triggers on 'clean readwise', 'archive shorts', 'readwise cleanup', 'organize readwise', 'run readwise scripts', 'remove shorts'."
---

# Readwise Cleaner

Run both Readwise cleanup scripts in parallel to organize YouTube content in Readwise Reader.

## Script Locations

```
$HOME/Developer/clitools/readwiseshortremover/readwise/
```

Python venv: `.venv/` or `venv/` inside that directory.

## Steps

1. Activate the venv:
   ```bash
   SCRIPT_DIR="$HOME/Developer/clitools/readwiseshortremover/readwise"
   source "$SCRIPT_DIR/.venv/bin/activate" 2>/dev/null || source "$SCRIPT_DIR/venv/bin/activate"
   ```

2. Launch **both** scripts simultaneously (not sequentially):
   - `python "$SCRIPT_DIR/main.py"` — finds YouTube Shorts, tags with `youtube-shorts`, archives them
   - `python "$SCRIPT_DIR/recategorize.py"` — moves YouTube videos from RSS → video category

3. Report combined summary when both complete:
   - Documents scanned
   - Shorts found and archived
   - Videos recategorized
   - Any errors from either script
