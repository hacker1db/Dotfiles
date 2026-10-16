---
description: Clean up YouTube content in Readwise Reader
agent: readwise-cleaner
---

Run both Readwise cleanup scripts to organize YouTube content.

The agent runs `main.py` to completion first, then `recategorize.py`. They must not run concurrently because both modify the same RSS documents.
