# Blog Draft Generator

Generate blog posts for hacker1db.dev with automatic security filtering and brand voice.

**Before writing any content**, read the shared reference at `$HOME/.config/blog/hacker1db-voice.md` for brand voice, security filters, and the SVX frontmatter schema. That file is the single source of truth — follow it exactly.

## Commands

### /blog-draft [topic]

Generate a complete blog post draft.

1. Read `$HOME/.config/blog/hacker1db-voice.md`
2. **Check for existing notes and Readwise highlights** — run both searches in parallel:
   - Search `$HOME/notes/SecondBrain/` (work notes, quick notes, existing drafts) for files related to the topic
   - Invoke the `readwise-research` agent to search Readwise for saved articles, books, and podcasts on the topic
   Show the user what was found and ask: "I found these related notes and Readwise sources — should I use them?" If yes (or unspecified), use them as the foundation.
3. Apply security filters from the reference — especially important when pulling from work notes
4. Search Unsplash for a cover image — WebSearch `site:unsplash.com [topic keywords]`, extract the photo ID, construct `https://images.unsplash.com/photo-{id}?w=1200`, note the photographer name
5. Generate frontmatter using the SVX schema (with `draft: true`), including the `thumbnail` field
6. Add `<!-- Photo by [Name] on Unsplash -->` on the first line after the closing `---`
7. Create structured content following the content patterns — grounded in vault notes where available
8. Include "wrong vs. right" code examples where applicable
9. Add actionable takeaways and community engagement CTA
10. Save to `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/[Title].md`

**Examples:**
```
/blog-draft Implementing Pre-Commit Hooks for Security
/blog-draft API Security Best Practices
/blog-draft Container Hardening with Docker
```

### /blog-from-notes [topic] [note paths...]

Generate a blog post using specific vault notes as source material. Read the notes, synthesize into a cohesive post, apply voice and filters.

```
/blog-from-notes Container Security 2.Areas/Work Notes/DevSecOps/Docker.md
```

### /blog-outline [topic] [style]

Create a detailed outline. Styles: `guide` (default), `tutorial`, `opinion`.

Output: working title, opening hook, 3-5 main sections with key points, code examples to include, conclusion approach, suggested tags and series.

### /blog-improve [path]

Improve an existing draft. Checks: security filter compliance, brand voice, structure, code examples, actionability.

### /blog-ideas [tag] [limit]

Generate blog post ideas from vault notes. Scans existing posts to avoid duplication. Default limit: 5.

### /blog-social [path] [platform]

Generate social media snippets. Platforms: `twitter` (default, 280 char), `linkedin`.

### /blog-seo [path]

SEO optimization: primary keyword, meta description (155 chars), link suggestions, header review, URL slug.

## Workflow

```
/blog-ideas devsecops 5        → pick a topic
/blog-outline [topic] tutorial  → review structure
/blog-draft [topic]             → generate draft
  [edit in Obsidian]
/blog-improve [path]            → polish
/md-to-svx [post name]          → convert to .svx and place in blog repo
```

## Output Location

All drafts: `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/[Title].md`
