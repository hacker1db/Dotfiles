---
name: blog-draft
description: Generates blog post drafts for hacker1db.dev with automatic security filtering (removes company/internal details) and brand voice application. Use when the user wants to write a blog post, draft content, create an outline, generate blog ideas, improve a draft, or create social media snippets.
model: claude-opus-4-6
---

Generate blog posts for hacker1db.dev. Before writing any content, read the shared reference at `$HOME/.config/blog/hacker1db-voice.md` for brand voice, security filters, and frontmatter schema.

## Sub-commands

### /blog-draft [topic]
Generate a complete blog post draft.

1. Read `$HOME/.config/blog/hacker1db-voice.md`
2. **Check for existing vault notes and Readwise highlights** — run both searches in parallel:
   - Search `$HOME/notes/SecondBrain/` (work notes, quick notes, existing drafts) for files related to the topic
   - Use the `readwise-research` agent to search `4.Resources/Readwise/` for saved articles, books, and podcasts on the topic
   Show the user what was found and ask: "I found these related notes and Readwise sources — should I use them?" If yes (or unspecified), use them as the foundation. If nothing found, generate from scratch.
3. Apply security filters from the reference — especially important when pulling from work notes
4. Search Unsplash for a relevant cover image — WebSearch `site:unsplash.com [topic keywords]`, pick a photo, extract the ID, construct `https://images.unsplash.com/photo-{id}?w=1200`. Note photographer name.
5. Generate frontmatter using the SVX schema (with `draft: true`), including `thumbnail`
6. Add photographer credit as an HTML comment after the closing `---`: `<!-- Photo by [Name] on Unsplash -->`
7. Create structured content following the content patterns — grounded in vault notes where available, supplemented with your knowledge
8. Include "wrong vs. right" code examples where applicable
9. Add actionable takeaways and community engagement CTA
10. Save to `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/[Title].md`

### /blog-from-notes [topic] [note paths...]
Generate a blog post using specific vault notes as source material. Read the notes first, synthesize into a cohesive post, apply voice and filters.

### /blog-outline [topic] [style]
Create a detailed outline before writing. Styles: `guide` (default), `tutorial`, `opinion`.

Output: working title, opening hook, 3-5 main sections with key points, code examples to include, conclusion approach, suggested tags and series.

### /blog-improve [path]
Improve an existing draft.

1. Read the draft and check: security filter compliance, brand voice, structure (h2/h3/h4), code examples, actionability
2. If the post's `series` is `CyberSecurity`, `DevSecOps`, or `Security` — also spawn `oh-my-claudecode:security-reviewer` to check technical accuracy of security claims and code examples. Incorporate any findings before saving.
3. Output improved version with a list of changes made

### /blog-ideas [tag] [limit]
Generate blog post ideas from vault notes. Scans existing posts to avoid duplication. Default limit: 5.

### /blog-social [path] [platform]
Generate social media snippets. Platforms: `twitter` (default, 280 char), `linkedin` (longer format). Outputs 3 variations with hashtags and CTA.

### /blog-seo [path]
SEO optimization: primary keyword, meta description (155 chars), internal/external link suggestions, header structure review, URL slug recommendation. No keyword stuffing.

## Workflow

```
/blog-ideas devsecops 5        → pick a topic
/blog-outline [topic] tutorial  → review structure
/blog-draft [topic]             → generate draft
  [edit in Obsidian]
/blog-improve [path]            → polish
/md-to-svx [post name]          → convert and publish to blog repo
```

## Output Location

All drafts saved to: `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/[Title].md`
