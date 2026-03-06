---
name: blog-draft
description: Generates blog post drafts for hacker1db.dev with automatic security filtering (removes company/internal details) and brand voice application
model: claude-opus-4-6
---

Generate blog posts for hacker1db.dev with automatic security filtering and brand voice.

## Available Sub-commands

### /blog-draft [topic]
Generate a complete blog post draft saved to `2.Areas/Personal Home/Blog Posts 🕸/`.

Steps:
1. Read brand voice from `.opencode/brand/hacker1db-voice.md` if it exists
2. Apply security filters (removes company names, internal details, sensitive data)
3. Generate frontmatter with `draft: true`
4. Create structured content with h2/h3/h4 hierarchy
5. Include "wrong vs. right" code examples
6. Add actionable takeaways and community engagement CTA
7. Save to `2.Areas/Personal Home/Blog Posts 🕸/[Title].md`

### /blog-from-notes [topic] [note paths...]
Generate a blog post using specific vault notes as source material.

### /blog-outline [topic] [style]
Create a detailed outline. Styles: `guide` (default), `tutorial`, `opinion`.

### /blog-improve [path]
Improve an existing draft with brand voice and security filtering.

### /blog-ideas [tag] [limit]
Generate blog post ideas from vault notes.

### /blog-social [path] [platform]
Generate social media snippets. Platforms: `twitter` (default), `linkedin`.

### /blog-seo [path]
Optimize a blog post for SEO while maintaining technical quality.

## Security Filters (Automatic)

### NEVER Include:
- Company names (Alaska Airlines, specific employers) → "at a Fortune 500 airline"
- Colleague names or internal teams → "security lead" or omitted
- Internal URLs, IP addresses, infrastructure details → abstracted
- Proprietary tools unique to employer → "custom tooling"
- Specific vulnerabilities in employer systems → generic patterns only
- Budget numbers or staffing details → omitted
- Unreleased product information → omitted

### Safe to Include:
- Open-source tools and public frameworks (OWASP, NIST, CIS)
- Publicly documented best practices
- Generic implementation patterns
- Personal learning experiences (genericized)
- Public CVE information
- Community security research

## Brand Voice (hacker1db.dev)

- Practical & Hands-On — Real code, real commands, real implementation
- Technically Credible — Deep understanding, precise terminology
- Educator, Not Lecturer — Break down complexity, anticipate questions
- Honest & Direct — Acknowledge trade-offs, no security theater
- Structured & Organized — Clear hierarchy, scannable format

## Content Patterns

- Start with problem/hook
- Include "wrong vs right" code examples
- Use h2/h3/h4 hierarchy
- Provide actionable takeaways
- End with community engagement question

## Frontmatter Template

```yaml
---
title: "[Title]: A Practical Guide"
date: [today]
author: "David Walters"
tags: ["tag1", "tag2"]
categories: ["DevSecOps", "Security"]
description: "One-sentence hook"
draft: true
featured: false
---
```

## Output Location

All blog posts saved to: `2.Areas/Personal Home/Blog Posts 🕸/[Title].md`
