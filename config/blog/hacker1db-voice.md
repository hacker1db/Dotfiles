# hacker1db.dev — Blog Reference

Shared reference for all blog agents (Claude Code, OpenCode). Read this file when generating, improving, or converting blog content.

## Brand Voice

- **Practical & Hands-On** — Real code, real commands, real implementation. No hand-wavy theory without something the reader can run.
- **Technically Credible** — Deep understanding, precise terminology. Readers are developers and security engineers.
- **Educator, Not Lecturer** — Break down complexity, anticipate questions. Meet the reader where they are.
- **Honest & Direct** — Acknowledge trade-offs, no security theater. If something sucks, say so.
- **Structured & Organized** — Clear hierarchy, scannable format. Busy people skim first.

## Content Patterns

- Open with a problem/hook — why should the reader care?
- Include "wrong vs. right" code examples with explanations
- Use h2/h3/h4 hierarchy (no h1 in body — title handles that via frontmatter)
- Provide actionable takeaways the reader can apply today
- End with a community engagement question

## Security Filters (Automatic — Always Applied)

### NEVER include:
- Employer names → "at a Fortune 500 company" or "in the airline industry"
- Colleague names or internal teams → "security lead", "a team member"
- Internal URLs, IP addresses, infrastructure details → abstracted
- Proprietary tools unique to employer → "custom tooling" or generic description
- Specific vulnerabilities in employer systems → generic patterns only
- Budget numbers, staffing details, org charts → omitted
- Unreleased product information → omitted

### Safe to include:
- Open-source tools and public frameworks (OWASP, NIST, CIS)
- Publicly documented best practices
- Generic implementation patterns
- Personal learning experiences (genericized)
- Public CVE information
- Community security research

## SVX Frontmatter Schema

All blog posts — whether drafted in Obsidian or written directly — should use this frontmatter format. This is the format consumed by the SvelteKit blog (mdsvex).

```yaml
---
title: "Post Title: Optional Subtitle"
date: YYYY-MM-DD
thumbnail: "https://images.unsplash.com/photo-XXXXXXXXXX?w=1200"
author: hacker1db
subtitle: "One-sentence hook that appears below the title"
tags:
  - "tag1"
  - "tag2"
  - "tag3"
series: []
youtube: ""
toc: true
draft: true
---
```

### Field notes:
- **author**: `hacker1db` — no quotes, this is the blog identity
- **date**: No quotes, ISO format `YYYY-MM-DD`
- **thumbnail**: Unsplash URL with `?w=1200`. Always search Unsplash for a relevant photo — use WebSearch with `site:unsplash.com [topic keywords]`. Extract the photo ID and construct `https://images.unsplash.com/photo-{id}?w=1200`. Add photographer credit as an HTML comment on the first line after the closing `---`: `<!-- Photo by [Name] on Unsplash -->`
- **subtitle**: Compelling one-liner (was `description` in older posts — always use `subtitle` going forward)
- **tags**: YAML list format (not inline array)
- **series**: Empty array `[]` by default. Only populate if the post is explicitly part of a named series.
- **youtube**: Empty string unless there's an associated video
- **toc**: Default `true` — generates table of contents
- **draft**: Start as `true`, flip to `false` when ready to publish

### Fields to NOT include (Obsidian-only):
`aliases`, `cssclass`, `cssclasses`, `publish`, `featured`, `permalink`, `uid`, `categories` (map to `series`), `description` (map to `subtitle`)

## Blog Repo Layout

The SvelteKit blog lives at `$HOME/Developer/side-code/web-hacker1db/`.
It uses a bare repo with worktrees. To find the active SvelteKit worktree, look for the one containing `svelte.config.js`.

Content goes in: `{worktree}/content/posts/{Category}/`

Categories (directory names — these are exact):
- `CyberSecurity/`
- `DevOps/`
- `Programing/` (note the spelling — matches existing directory)
- `Testing/`

## Obsidian Vault

Blog drafts live at: `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/`

Research sources in the vault:
- `2.Areas/Work Notes/DevSecOps Notes/` — work learnings
- `4.Resources/AppSec/` — application security resources
- `4.Resources/Readwise/` — saved articles and highlights
- `0.Quick Notes 📨/` — recent captures
