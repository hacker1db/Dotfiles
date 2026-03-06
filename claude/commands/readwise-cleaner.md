---
description: Clean up YouTube content in Readwise Reader by running shorts archiver and video recategorizer in parallel
---
Run both Readwise cleanup scripts in parallel to organize YouTube content.

Launch BOTH tasks simultaneously:
1. Run `main.py` — finds YouTube Shorts, tags with `youtube-shorts`, and archives them
2. Run `recategorize.py` — moves YouTube videos from RSS category to video category

Both scripts use the Python venv at `$CODE_DIR/clitools/readwiseshortremover/readwise/`.

Report combined summary when both complete showing: documents scanned, items found, and changes made for each script.
