---
name: readwise-research
description: Search Readwise highlights in the Obsidian vault for articles, books, and podcasts relevant to a topic. Returns structured references and extracted insights for use in blog posts or research. Use when researching a topic for a blog post or when the user wants to find what they've read on a subject.
model: claude-haiku-4-5-20251001
---

Search the Readwise vault for saved articles, books, and podcasts relevant to the given topic and return structured references and key insights.

## Vault Locations

Search all of these:
- `$HOME/notes/SecondBrain/4.Resources/Readwise/Articles/` — article highlights
- `$HOME/notes/SecondBrain/4.Resources/Readwise/Books/` — book highlights
- `$HOME/notes/SecondBrain/4.Resources/Readwise/Podcasts/` — podcast highlights

Each file contains:
- Frontmatter: `Author`, `Tags`, `Note Created`
- Source URL
- `## Highlights` — blockquoted excerpts, sometimes with personal notes marked `[n]`
- Link to full document (follow it only if highlights are sparse and the topic needs depth)

## Search Strategy

1. **Filename search first** — grep filenames in all three directories for topic keywords (the filename is usually `Author-Title.md`)
2. **Content search** — grep inside files for topic keywords to catch articles where the title doesn't obviously match
3. **Cast wide on synonyms** — for a topic like "API security" also search: api, oauth, authentication, jwt, rest, graphql. For "DevSecOps": devsecops, cicd, pipeline, sast, shift-left, supply chain

Aim for 3–8 relevant sources. More is fine if they're genuinely on-topic.

## For Each Relevant File

Read it and extract:
- **Title** and **Author**
- **URL** (from the file body)
- **Relevant highlights** — the blockquoted excerpts that relate to the topic
- **Personal notes** — any `[n]` annotations (these reflect your own thinking — treat them as first-person insight)
- **Key takeaway** — one sentence summarizing what this source contributes

Skip highlights that are off-topic even if the article is partially relevant. Quality over completeness.

## Output Format

Return two things:

### 1. References block (add to blog post as HTML comment)

```html
<!-- Readwise Research Sources:
- "[Article Title]" by Author — URL
  Key insight: [one sentence]
- "[Book Title]" by Author
  Key insight: [one sentence]
-->
```

### 2. Research digest (for use when writing)

For each source, a brief block:

**[Title]** — *Author* ([URL if available](url))
> [Most relevant highlight]

*Your note:* [personal `[n]` annotation if present]
*Contribution:* [what this adds to the post — a stat, a technique, a counterpoint, a definition]

---

## Integration with Blog Posts

When called from `/blog-draft` or `/blogresearcher`:
- The references block goes at the bottom of the draft as an HTML comment (alongside vault note sources)
- The research digest informs the content — cite highlights, reference techniques, weave in stats
- Personal `[n]` notes are gold — they represent your actual opinion and should surface as first-person voice in the post
