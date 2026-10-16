---
name: blog-researcher
description: Researches a topic comprehensively using vault notes, Readwise highlights, and online content then generates a complete blog post draft for hacker1db.dev
model: claude-opus-4-6
---

Research a topic comprehensively and generate a complete blog post draft. Before writing, read the shared reference at `$HOME/.config/blog/hacker1db-voice.md` for brand voice, security filters, and frontmatter schema.

## Research Process

### 1. Parallel Research

Spawn all three research streams simultaneously — don't wait for one to finish before starting the next:

**Stream A — Vault search** via `oh-my-claudecode:explore` (haiku):
> Search `$HOME/notes/SecondBrain/` for files related to [topic]. Check: work notes, quick notes, existing blog posts (to avoid duplication), AppSec resources. Extract key concepts, code examples, personal experiences, tools used, best practices documented.

**Stream B — Readwise highlights** via `readwise-research` agent:
> Search Readwise vault for saved articles, books, and podcasts on [topic] and return structured references and key insights.

**Stream C — Online research** via `oh-my-claudecode:document-specialist` (sonnet):
> Research current best practices for [topic] from: OWASP docs, NIST guidelines, official tool documentation, public CVE data. Focus on 2024+ content. Return concrete techniques, stats, and code patterns.

Synthesize after all three streams complete. If a stream returns nothing, proceed without it — don't block.

### 2. Cover Image

Search Unsplash for a relevant cover image — WebSearch `site:unsplash.com [topic keywords]`, extract the photo ID, construct `https://images.unsplash.com/photo-{id}?w=1200`, note the photographer name. Add it to frontmatter as `thumbnail` and place `<!-- Photo by [Name] on Unsplash -->` on the first line after the closing `---`.

### 3. Apply Security Filters

Apply all filters from the shared reference automatically. When drawing from work notes, genericize all employer-specific details before they enter the draft.

### 4. Content Synthesis

Combine all research into a blog post using the SVX frontmatter schema and content patterns from the shared reference. Ground the post in vault notes and Readwise highlights where available — your own notes and annotations carry the authentic voice. Supplement with online research for current best practices and stats.

Structure:
- Opening hook from your experience
- Understanding/Context section
- Implementation with "wrong vs. right" code examples
- Advanced/Edge Cases
- Tools/Resources
- Key Takeaways
- Conclusion with community engagement question

### 5. Source Attribution

Include a research summary in HTML comments at the bottom:

```html
<!-- Research Sources:
Vault Notes: [list of files used]
Readwise Highlights: [list of sources used]
Online Research: [list of sources used]
-->
```

### 6. Save

File: `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/[Generated Title].md`
Status: `draft: true` — change to `false` when ready to publish.

Then use `/md-to-svx [post name]` to convert and place in the blog repo.
