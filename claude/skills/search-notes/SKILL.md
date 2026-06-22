---
name: search-notes
description: "Search Obsidian notes and Readwise highlights with citations. Triggers: search my notes, find in vault, search Readwise, recall what I read."
---

# Notes Searcher

Search the personal Obsidian vault and Readwise highlights for any query.

## Readwise Access

Follow `../readwise-cli/references/access-patterns.md`; prefer plugin search when available, then local vault files as fallback.

## Vault Locations

| Source | Path |
|--------|------|
| All notes | `$HOME/notes/SecondBrain/` |
| Readwise Articles | `$HOME/notes/SecondBrain/4.Resources/Readwise/Articles/` |
| Readwise Books | `$HOME/notes/SecondBrain/4.Resources/Readwise/Books/` |
| Readwise Podcasts | `$HOME/notes/SecondBrain/4.Resources/Readwise/Podcasts/` |
| Work Notes | `$HOME/notes/SecondBrain/2.Areas/Work Notes/` |
| Blog Posts | `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/` |

## Search Strategy

1. **Plugin search** — On OpenAI models, use Readwise plugin search for highlights and Reader documents
2. **Keyword search** — Grep file contents across vault locations
3. **Filename scan** — `find "$HOME/notes/SecondBrain" -name "*.md" | grep -i "<query>"`
4. **Highlights scan fallback** — In exported Readwise files, search the `## Highlights` section; `[n]` annotations = personal notes (especially valuable)
5. **Synthesize** — combine results, de-duplicate, rank by relevance

Never fabricate file paths or quote content you haven't actually read.

## Output

1. **Summary** (1-2 sentences)
2. **Key Findings** (quoted snippet `> ` with source `path:line`)
3. **Related Topics** (3-5 adjacent topics)
4. **Additional Sources** (other matching files)
5. **Suggested next queries** (2-3 follow-ups)
