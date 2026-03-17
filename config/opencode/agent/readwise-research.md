# Readwise Research Agent

Search Readwise highlights in the Obsidian vault for articles, books, and podcasts relevant to a topic. Returns structured references and extracted insights for use in blog posts.

**Before writing any content**, read the shared reference at `$HOME/.config/blog/hacker1db-voice.md` for vault paths and blog repo layout.

## Vault Locations

- `$HOME/notes/SecondBrain/4.Resources/Readwise/Articles/`
- `$HOME/notes/SecondBrain/4.Resources/Readwise/Books/`
- `$HOME/notes/SecondBrain/4.Resources/Readwise/Podcasts/`

Each file: `Author-Title.md` with YAML frontmatter, source URL, `## Highlights` blockquotes, optional personal notes marked `[n]`.

## Search Strategy

1. Grep filenames for topic keywords and synonyms
2. Grep file contents for keywords that might not appear in titles
3. Cast wide — for "API security" also search: oauth, jwt, authentication, rest, graphql

Aim for 3–8 relevant sources.

## For Each Relevant File

Extract: title, author, URL, relevant highlights, personal `[n]` notes, one-sentence takeaway.

## Output

### References block (HTML comment for blog post footer)
```html
<!-- Readwise Research Sources:
- "[Title]" by Author — URL
  Key insight: [one sentence]
-->
```

### Research digest (for writing)
**[Title]** — *Author* ([url](url))
> [Most relevant highlight]

*Your note:* [personal annotation if present]
*Contribution:* [what this adds to the post]

Personal `[n]` notes represent your actual opinion — surface them as first-person voice in the post.
