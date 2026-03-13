# Blog Draft Generator

Slash commands for creating blog posts for hacker1db.dev with automatic security filtering and brand voice.

## Available Commands

### /blog-draft [topic]

Generate a complete blog post draft and save it to `2.Areas/Personal Home/Blog Posts 🕸/`.

**What it does:**
1. Reads brand voice from `.opencode/brand/hacker1db-voice.md`
2. Applies security filters (removes company names, internal details, sensitive data)
3. Generates frontmatter with `draft: true`
4. Creates structured content with h2/h3/h4 hierarchy
5. Includes "wrong vs. right" code examples
6. Adds actionable takeaways and community engagement CTA
7. Saves to `2.Areas/Personal Home/Blog Posts 🕸/[Title].md`

**Usage:**
```
/blog-draft Implementing Pre-Commit Hooks for Security
/blog-draft API Security Best Practices
/blog-draft Container Hardening with Docker
```

**Example:**
```
/blog-draft Building a Secure CI/CD Pipeline
```

Generates: `2.Areas/Personal Home/Blog Posts 🕸/Building a Secure CI/CD Pipeline.md`

```yaml
---
title: "Building a Secure CI/CD Pipeline: A Practical Guide"
date: 2025-01-17
author: "David Walters"
tags: ["cicd", "security", "devsecops", "pipeline-security"]
categories: ["DevSecOps", "Security", "CI/CD"]
description: "Learn how to integrate security into your CI/CD pipeline without slowing down development."
draft: true
featured: false
---
```

### /blog-from-notes [topic] [note paths...]

Generate a blog post using specific vault notes as source material.

**Usage:**
```
/blog-from-notes Container Security 2.Areas/Work Notes/DevSecOps/Docker.md 4.Resources/Security/Containers.md
/blog-from-notes Kubernetes RBAC 2.Areas/Work Notes/K8s/RBAC.md
```

**What it does:**
1. Reads specified note files
2. Synthesizes content from multiple notes
3. Applies brand voice and security filters
4. Generates cohesive blog post
5. Saves to `2.Areas/Personal Home/Blog Posts 🕸/[Title].md` with `draft: true`

### /blog-outline [topic] [style]

Create a detailed outline before writing.

**Styles:**
- `guide` (default) - Comprehensive how-to
- `tutorial` - Step-by-step walkthrough
- `opinion` - Analysis or hot take

**Usage:**
```
/blog-outline API Security Patterns guide
/blog-outline Why Security Tools Fail opinion
/blog-outline Container Scanning Tutorial tutorial
```

**Output:**
- Working title with subtitle
- Opening hook
- Main sections (3-5 major topics)
- Key points under each section
- Code examples to include
- Conclusion approach
- Suggested tags and categories

### /blog-improve [path]

Improve an existing draft with brand voice and security filtering.

**Usage:**
```
/blog-improve 2.Areas/Personal Home/Blog Posts 🕸/API Security Patterns.md
/blog-improve 2.Areas/Personal Home/Blog Posts 🕸/Container Security.md
```

**What it checks:**
1. ❌ Security Filter - Removes company names, internal details, sensitive data
2. ✅ Brand Voice - Ensures hacker1db.dev style (practical, technical, honest)
3. ✅ Structure - Clear h2/h3/h4 hierarchy and logical flow
4. ✅ Code Examples - "Wrong vs right" patterns with explanations
5. ✅ Actionability - Practical takeaways readers can apply

**Output:**
- Improved version with tracked changes
- List of security-filtered items (what was removed/changed)
- Suggestions for additional improvements

### /blog-ideas [tag] [limit]

Generate blog post ideas from your vault notes.

**Usage:**
```
/blog-ideas devsecops 10
/blog-ideas kubernetes 5
/blog-ideas appsec
```

**What it does:**
1. Scans existing posts in `2.Areas/Personal Home/Blog Posts 🕸/`
2. Analyzes your vault notes for topics
3. Generates unique ideas (avoids duplication)
4. Focuses on DevSecOps, application security, security education
5. Matches hacker1db.dev practical tone

**Output format:**
```
1. **Title**: Implementing Secret Scanning in CI/CD
   **Type**: Tutorial
   **Audience**: DevOps engineers adding security
   **Description**: Step-by-step guide to detecting hardcoded secrets...

2. **Title**: Common API Security Vulnerabilities
   **Type**: Guide
   **Audience**: Backend developers
   **Description**: Practical overview of OWASP API Top 10...
```

### /blog-social [path] [platform]

Generate social media snippets for a blog post.

**Platforms:**
- `twitter` (default) - 280 character limit
- `linkedin` - Professional tone, longer format

**Usage:**
```
/blog-social 2.Areas/Personal Home/Blog Posts 🕸/Building a DevSecOps Program.md twitter
/blog-social 2.Areas/Personal Home/Blog Posts 🕸/Pre Commit hooks for DevSecOps.md linkedin
```

**Output:**
- 3 variations of platform-optimized posts
- Relevant hashtags
- Hook that drives clicks
- Technical credibility maintained
- Clear call-to-action

### /blog-seo [path]

Optimize a blog post for SEO while maintaining technical quality.

**Usage:**
```
/blog-seo 2.Areas/Personal Home/Blog Posts 🕸/API Security Patterns.md
```

**Provides:**
1. Primary keyword recommendation
2. Meta description (155 chars max, compelling)
3. Suggested internal/external links
4. Header structure review (H1/H2/H3 optimization)
5. Alt text suggestions for code examples
6. URL slug recommendation
7. Schema.org markup suggestions (TechArticle, HowTo, etc.)

**Note:** No keyword stuffing or SEO spam - maintains hacker1db.dev voice.

## Security Filters (Automatic)

All generated content automatically filters:

### ❌ NEVER Includes:
- Company names (Alaska Airlines, specific employers) → "at a Fortune 500 airline"
- Colleague names or internal teams → "security lead" or omitted
- Internal URLs, IP addresses, infrastructure details → abstracted
- Proprietary tools unique to employer → "custom tooling"
- Specific vulnerabilities in employer systems → generic patterns only
- Budget numbers or staffing details → omitted
- Unreleased product information → omitted

### ✅ Safe to Include:
- Open-source tools and public frameworks (OWASP, NIST, CIS)
- Publicly documented best practices
- Generic implementation patterns
- Personal learning experiences (genericized)
- Public CVE information
- Community security research

## Brand Voice (hacker1db.dev)

All generated content matches your established voice:

**Characteristics:**
- ✅ Practical & Hands-On - Real code, real commands, real implementation
- ✅ Technically Credible - Deep understanding, precise terminology
- ✅ Educator, Not Lecturer - Break down complexity, anticipate questions
- ✅ Honest & Direct - Acknowledge trade-offs, no security theater
- ✅ Structured & Organized - Clear hierarchy, scannable format

**Content Patterns:**
- Start with problem/hook
- Include "wrong vs right" code examples
- Use h2/h3/h4 hierarchy
- Provide actionable takeaways
- End with community engagement question

## Workflow Examples

### Quick Draft (Start to Finish)
```
1. /blog-ideas devsecops 5
   → Pick: "Implementing Secret Scanning in CI/CD"

2. /blog-outline Implementing Secret Scanning in CI/CD tutorial
   → Review outline, verify structure

3. /blog-draft Implementing Secret Scanning in CI/CD
   → Saved to: 2.Areas/Personal Home/Blog Posts 🕸/Implementing Secret Scanning in CI/CD.md
   → Status: draft: true

4. [Edit in Obsidian, add personal examples]

5. /blog-improve 2.Areas/Personal Home/Blog Posts 🕸/Implementing Secret Scanning in CI/CD.md
   → Review security filters, apply suggestions

6. [Change draft: false in frontmatter]

7. /blog-social 2.Areas/Personal Home/Blog Posts 🕸/Implementing Secret Scanning in CI/CD.md twitter

8. /blog-seo 2.Areas/Personal Home/Blog Posts 🕸/Implementing Secret Scanning in CI/CD.md

9. Publish to hacker1db.dev!
```

### Draft from Existing Notes
```
1. /blog-from-notes Container Security Best Practices 2.Areas/Work Notes/DevSecOps/Docker.md 4.Resources/Security/Containers.md
   → Synthesizes notes into cohesive post
   → Saved with draft: true

2. [Review and edit]

3. /blog-improve 2.Areas/Personal Home/Blog Posts 🕸/Container Security Best Practices.md

4. [Publish]
```

### Weekly Content Planning
```
1. /blog-ideas devsecops 10
   → Review and select top 3

2. /blog-outline [Idea 1] guide
3. /blog-outline [Idea 2] tutorial
4. /blog-outline [Idea 3] opinion
   → Review outlines, pick one to write

5. /blog-draft [Selected Topic]
   → Write, improve, publish
```

## Output Location

All blog posts are saved to:
```
2.Areas/Personal Home/Blog Posts 🕸/[Title].md
```

**Frontmatter Status:**
- Generated with `draft: true`
- Change to `draft: false` when ready to publish
- Set `featured: true` for homepage highlight

## Configuration

**Brand Voice:** `.opencode/brand/hacker1db-voice.md`
- Edit to refine voice characteristics
- Update security filter patterns
- Modify content structure preferences
- Changes apply immediately (no restart)

## Tips

1. **Start with Outline**: Use `/blog-outline` to structure thinking before full draft
2. **Use Your Notes**: `/blog-from-notes` creates authentic content from your learning
3. **Always Improve**: Run `/blog-improve` before publishing to catch security leaks
4. **Batch Ideas**: Use `/blog-ideas` to plan content calendar in advance
5. **SEO Last**: Optimize after content is finalized with `/blog-seo`

## Troubleshooting

**Draft not saved**
→ Check you're in vault directory: `cd $HOME/notes/SecondBrain`

**Note files not found**
→ Use full paths from vault root: `2.Areas/Work Notes/...`

**Brand voice not applied**
→ Verify `.opencode/brand/hacker1db-voice.md` exists

**Security filters too aggressive**
→ Edit filter patterns in `.opencode/brand/hacker1db-voice.md`

---

**Start here:**
```
/blog-ideas devsecops 10
```

Pick a topic, then:
```
/blog-draft [Your Topic]
```

Edit in Obsidian, improve, publish. 🚀
