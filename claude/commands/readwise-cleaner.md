---
description: Clean up YouTube content in Readwise Reader by running shorts archiver and video recategorizer in parallel
---
Run both Readwise cleanup scripts in parallel to organize YouTube content.

## Script Locations

Both scripts live at: `$HOME/Developer/clitools/readwiseshortremover/readwise/`
Python venv: `$HOME/Developer/clitools/readwiseshortremover/readwise/.venv/` (or `venv/`)

Activate venv before running:
```bash
SCRIPT_DIR="$HOME/Developer/clitools/readwiseshortremover/readwise"
source "$SCRIPT_DIR/.venv/bin/activate" 2>/dev/null || source "$SCRIPT_DIR/venv/bin/activate"
```

## Launch BOTH tasks simultaneously:

1. `python "$SCRIPT_DIR/main.py"` — finds YouTube Shorts, tags with `youtube-shorts`, archives them
2. `python "$SCRIPT_DIR/recategorize.py"` — moves YouTube videos from RSS → video category

## Output

Report combined summary when both complete:
- Documents scanned, Shorts found/archived, videos recategorized
- Any errors encountered by either script
