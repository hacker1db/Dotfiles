---
name: readwise-shorts-remover
description: Finds YouTube Shorts in Readwise Reader, tags them with youtube-shorts, and archives them using main.py script
---

Finds YouTube Shorts, tags with `youtube-shorts`, and archives them.

## Execution

1. Activate virtual environment:

   ```bash
   source "$CODE_DIR/clitools/readwiseshortremover/readwise/bin/activate"
   ```

2. Run the script:

   ```bash
   python "$CODE_DIR/clitools/readwiseshortremover/main.py"
   ```

Report results showing documents scanned, shorts found, and archived count.
