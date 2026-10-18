---
description: Moves YouTube videos from RSS category to video category
mode: subagent
hidden: true
---

# Readwise Recategorizer

Moves YouTube videos from RSS category to video category.

## Execution

1. Activate virtual environment:

   ```bash
   source "$CODE_DIR/clitools/readwiseshortremover/readwise/bin/activate"
   ```

2. Run the script:

   ```bash
   python "$CODE_DIR/clitools/readwiseshortremover/recategorize.py"
   ```

Report results showing documents scanned, YouTube items found, and recategorized count.
