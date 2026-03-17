# Blog Researcher

Research a topic comprehensively and generate a complete blog post draft for hacker1db.dev.

**Before writing any content**, read the shared reference at `$HOME/.config/blog/hacker1db-voice.md` for brand voice, security filters, and the SVX frontmatter schema. That file is the single source of truth.

## Command

### /blogresearcher [topic]

```
/blogresearcher Implementing Pre-Commit Hooks for Security
/blogresearcher API Security Best Practices
/blogresearcher Kubernetes RBAC Essentials
```

## Research Process

### 1. Parallel Research

Kick off all three research streams at once — don't wait for one to finish before starting the next:

**Stream A — Vault search:**
Search `$HOME/notes/SecondBrain/` for files related to [topic]. Check: work notes, quick notes, existing blog posts (to avoid duplication), AppSec resources. Extract key concepts, code examples, personal experiences, tools used, best practices.

**Stream B — Readwise highlights:**
Invoke the `readwise-research` agent to search Readwise for saved articles, books, and podcasts on [topic]. Return structured references and key insights.

**Stream C — Online research:**
Research current best practices for [topic] from OWASP docs, NIST guidelines, official tool documentation, public CVE data. Focus on 2024+ content.

Synthesize after all three complete. If a stream returns nothing, proceed without it.

### 2. Cover Image

Search Unsplash for a relevant cover image — WebSearch `site:unsplash.com [topic keywords]`, extract the photo ID, construct `https://images.unsplash.com/photo-{id}?w=1200`, note the photographer name. Add it to frontmatter as `thumbnail` and place `<!-- Photo by [Name] on Unsplash -->` on the first line after the closing `---`.

### 3. Security Filtering

Apply all filters from the shared reference automatically. Genericize all employer-specific details from work notes before they enter the draft.

### 4. Content Synthesis

Combine all research into a blog post using the SVX frontmatter schema and content patterns from the shared reference. Ground the post in vault notes and Readwise highlights — your own notes carry the authentic voice. Supplement with online research for current best practices.

Structure:
- Opening hook from your experience
- Understanding/Context section
- Implementation with "wrong vs. right" code examples
- Advanced/Edge Cases
- Tools/Resources
- Key Takeaways
- Conclusion with community engagement question

### 5. Source Attribution

```html
<!-- Research Sources:
Vault Notes: [list of files used]
Readwise Highlights: [list of sources used]
Online Research: [list of sources used]
-->
```

## Output

File: `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/[Generated Title].md`
Status: `draft: true`

Then use `/md-to-svx [post name]` to convert and place in the blog repo.
