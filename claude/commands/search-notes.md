---
description: Hybrid semantic search across personal Obsidian vault notes and Readwise highlights with source citations. Use this skill when the user wants to search their notes, find something in their vault, look up Readwise highlights, recall what they've read on a topic, or search their second brain. Triggers on "search my notes", "find in vault", "what do my notes say about", "look up in obsidian", "search readwise", "recall what I read about".
---
Search personal knowledge base for query: $ARGUMENTS

## Vault Locations

- **Obsidian notes:** `$HOME/notes/SecondBrain/`
- **Readwise Articles:** `$HOME/notes/SecondBrain/4.Resources/Readwise/Articles/`
- **Readwise Books:** `$HOME/notes/SecondBrain/4.Resources/Readwise/Books/`
- **Readwise Podcasts:** `$HOME/notes/SecondBrain/4.Resources/Readwise/Podcasts/`
- **Work Notes:** `$HOME/notes/SecondBrain/2.Areas/Work Notes/`
- **Blog Posts:** `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/`

## Search Strategy

1. **Keyword search** — use Grep to search file contents and filenames for the query terms across vault locations
2. **Filename scan** — `find "$HOME/notes/SecondBrain" -name "*.md" | grep -i "<query>"` for topic-named notes
3. **Highlights scan** — for Readwise files, search the `## Highlights` section for relevant blockquotes; personal `[n]` annotations are especially valuable
4. **Synthesize** — combine results, de-duplicate, rank by relevance

Never fabricate file paths or quote content you haven't read. If a file matches by name but is empty or off-topic, skip it.

## Output

1. **Summary** (1-2 sentences capturing the gist of what your notes say)
2. **Key Findings** (each with quoted snippet `> ` and source `path:line` or note title)
3. **Related Topics** (3-5 adjacent topics found in the notes)
4. **Additional Sources** (list of other matching files not quoted above)
5. **Suggested next queries** (2-3 follow-up searches)
