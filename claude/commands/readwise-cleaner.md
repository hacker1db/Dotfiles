---
description: Clean up YouTube content in Readwise Reader by running the shorts archiver, then the video recategorizer
---
Run both Readwise cleanup scripts, one after the other, to organize YouTube content.

## Script Locations

Both scripts live at: `$HOME/Developer/clitools/main/readwiseshortremover/readwise/`
Python venv: `$HOME/Developer/clitools/main/readwiseshortremover/readwise/.venv/` (or `venv/`)

Activate venv before running:
```bash
SCRIPT_DIR="$HOME/Developer/clitools/main/readwiseshortremover/readwise"
source "$SCRIPT_DIR/.venv/bin/activate" 2>/dev/null || source "$SCRIPT_DIR/venv/bin/activate"
```

## Run the tasks sequentially (wait for step 1 to exit before step 2):

Both mutate the same RSS documents, so they must not overlap: the Shorts remover scans video before RSS, and a Short moved from RSS to video mid-run by the recategorizer would escape archival.

1. `python "$SCRIPT_DIR/main.py"` — finds YouTube Shorts, tags with `youtube-shorts`, archives them
2. `python "$SCRIPT_DIR/recategorize.py"` — moves YouTube videos from RSS → video category

## Output

Report combined summary when both complete:
- Documents scanned, Shorts found/archived, videos recategorized
- Any errors encountered by either script
