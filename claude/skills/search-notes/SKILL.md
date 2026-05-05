---
name: search-notes
description: "Hybrid semantic search across personal Obsidian vault notes and Readwise highlights with source citations. Use this skill when the user wants to search their notes, find something in their vault, look up Readwise highlights, recall what they have read on a topic, or search their second brain. Triggers on 'search my notes', 'find in vault', 'what do my notes say about', 'look up in obsidian', 'search readwise', 'recall what I read about', 'find in my second brain'."
---

# Notes Searcher

Search the personal Obsidian vault and Readwise highlights for any query.

## Readwise Plugin

When running on an OpenAI model with the Readwise plugin available, search Readwise through the plugin before reading exported vault files:
- `_readwise_search_highlights` for highlighted passages and personal notes
- `_reader_search_documents` for Reader documents by content, title, URL, tags, or summary
- `_reader_get_document_details` and `_reader_get_document_highlights` when a result needs more context

Use the local vault paths below for Obsidian notes and as a fallback if plugin tools are unavailable.

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
