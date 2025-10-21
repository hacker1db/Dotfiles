# Blog Researcher

Comprehensive blog post research and generation for hacker1db.dev using vault notes, Readwise highlights, and online content.

## Command

### /blogresearcher [topic]

Research a topic comprehensively and generate a complete blog post draft saved to `2.Areas/Personal Home/Blog Posts 🕸/`.

**What it does:**
1. **Vault Research**: Searches your Obsidian notes for related content
2. **Readwise Integration**: Pulls relevant highlights and annotations
3. **Online Research**: Gathers current best practices and examples
4. **Content Synthesis**: Combines all sources into cohesive blog post
5. **Security Filtering**: Removes sensitive/company-specific information
6. **Brand Voice**: Applies hacker1db.dev style (practical, technical, honest)
7. **File Creation**: Saves to `2.Areas/Personal Home/Blog Posts 🕸/[Title].md` with `draft: true`

## Usage

```
/blogresearcher [Your Topic]
```

**Examples:**
```
/blogresearcher Implementing Pre-Commit Hooks for Security
/blogresearcher API Security Best Practices
/blogresearcher Container Hardening with Docker
/blogresearcher Kubernetes RBAC Essentials
/blogresearcher Secret Management in Microservices
/blogresearcher Building SAST into CI/CD
```

## Research Process

### 1. Vault Analysis
The command searches your Second Brain for:

**Areas Searched:**
- `2.Areas/Work Notes/DevSecOps Notes/` - Your work learnings
- `2.Areas/Work Notes/Ecomm/` - E-commerce security insights
- `4.Resources/AppSec/` - Application security resources
- `4.Resources/Readwise/` - Saved articles and highlights
- `0.Quick Notes 📨/` - Recent captures
- `2.Areas/Personal Home/Blog Posts 🕸/` - Existing posts (to avoid duplication)

**What it extracts:**
- ✅ Key concepts and definitions
- ✅ Code examples and patterns
- ✅ Personal experiences and lessons learned
- ✅ Tools and frameworks you've used
- ✅ Best practices you've documented

### 2. Readwise Highlights Integration

If `READWISE_API_KEY` is set, the command:

**Searches for:**
- Articles tagged with topic keywords
- Books with relevant highlights
- Recent saves related to the subject
- Your annotations and notes

**Filters by:**
- Relevance to topic
- Recency (prioritizes recent learning)
- Your tags (security, devsecops, appsec, etc.)

**Examples:**
```
Topic: "Container Security"
→ Searches Readwise for: container, docker, kubernetes, security, pods
→ Pulls highlights from relevant articles/books
→ Includes your annotations as "insider perspective"
```

### 3. Online Research

The command researches current best practices:

**Sources:**
- ✅ OWASP documentation (if relevant)
- ✅ NIST guidelines (for security topics)
- ✅ Official tool documentation
- ✅ Industry-standard patterns
- ✅ Public CVE data (for vulnerability topics)

**What it gathers:**
- Current recommendations (2024/2025)
- Code examples from official docs
- Common pitfalls and solutions
- Industry trends and adoption

**Exclusions:**
- ❌ Paywalled content
- ❌ Low-quality sources
- ❌ Outdated information (pre-2020 unless historical context)

### 4. Content Synthesis

Combines all research into blog post structure:

**Structure Created:**
```markdown
---
title: "[Topic]: A Practical Guide"
date: 2025-01-17
author: "David Walters"
tags: [auto-generated from topic]
categories: [DevSecOps, Security, relevant-category]
description: "One-sentence hook generated from content"
draft: true
featured: false
---

# [Title]

*Italicized subtitle explaining context*

[Opening hook - problem statement from your experience]

## [Main Section 1 - Understanding/Context]
- Definitions
- Why it matters
- Your perspective from vault notes

## [Main Section 2 - Implementation]
- Step-by-step guidance
- Code examples (wrong vs. right)
- Best practices from Readwise + online research

## [Main Section 3 - Advanced/Edge Cases]
- Common pitfalls from your notes
- Solutions and workarounds
- Production considerations

## [Main Section 4 - Tools/Resources]
- Recommended tools (open-source prioritized)
- Configuration examples
- Your experience with specific tools

## Key Takeaways
- Bulleted actionable items
- What to do next

## Conclusion
[Community engagement question]

---

*What's been your experience with [topic]? Share your thoughts.*
```

### 5. Security Filtering

Automatically removes:
- ❌ "Alaska Airlines" → "a Fortune 500 airline"
- ❌ Colleague names → "security lead", "team member"
- ❌ Internal URLs → "internal systems"
- ❌ Specific infrastructure → "cloud infrastructure"
- ❌ Proprietary tools → "custom tooling" or generic description
- ❌ Budget/org details → omitted
- ❌ Unreleased features → omitted

Keeps:
- ✅ Public tools (GitHub Actions, OWASP ZAP, etc.)
- ✅ Open-source frameworks
- ✅ Public CVE references
- ✅ Industry standards
- ✅ Your genericized learning experiences

### 6. Brand Voice Application

Ensures content matches hacker1db.dev style:

**Voice Traits:**
- Practical (real code, real commands)
- Technical (precise, credible)
- Educational (break down complexity)
- Honest (acknowledge trade-offs)
- Structured (scannable, hierarchical)

**Patterns Applied:**
- Problem/hook opening
- "Wrong vs. right" code examples
- h2/h3/h4 hierarchy
- Actionable takeaways
- Community engagement question

## Output Format

**File Location:**
```
2.Areas/Personal Home/Blog Posts 🕸/[Generated Title].md
```

**Frontmatter:**
```yaml
---
title: "Building a Secure CI/CD Pipeline: A Practical Guide"
date: 2025-01-17
author: "David Walters"
tags: ["cicd", "security", "devsecops", "pipeline-security", "automation"]
categories: ["DevSecOps", "Security", "CI/CD"]
description: "Learn how to integrate security into your CI/CD pipeline without slowing down development—practical examples and lessons from building programs at scale."
draft: true
featured: false
---
```

**Status:**
- Initial: `draft: true`
- After review: Change to `draft: false` to publish

## Research Sources Summary

Each generated blog includes a research summary (in comments):

```markdown
<!-- Research Sources:
Vault Notes:
- 2.Areas/Work Notes/DevSecOps Notes/CI-CD Security.md
- 4.Resources/AppSec/Pipeline Security.md

Readwise Highlights:
- "Securing the Pipeline" (5 highlights)
- "DevSecOps Handbook" (3 highlights)

Online Research:
- OWASP DevSecOps Guideline
- NIST SSDF Framework
- GitHub Actions Security Best Practices
-->
```

## Example Workflow

### Simple Topic Research
```
/blogresearcher API Security Best Practices
```

**Process:**
1. Searches vault for "API", "security", "REST", "authentication"
2. Pulls Readwise highlights tagged "api", "security", "appsec"
3. Researches OWASP API Top 10, current trends
4. Synthesizes into blog post structure
5. Applies security filters
6. Saves to `2.Areas/Personal Home/Blog Posts 🕸/API Security Best Practices.md`

**Time:** ~30 seconds

**Next Steps:**
1. Open in Obsidian
2. Review and add personal examples
3. Refine code snippets
4. Change `draft: false`
5. Publish

### Complex Topic Research
```
/blogresearcher Building a DevSecOps Program from Zero to Mature
```

**Process:**
1. Deep vault search across DevSecOps, program management, security transformation notes
2. Pulls extensive Readwise highlights on organizational change, security programs
3. Researches maturity models, industry frameworks
4. Synthesizes multi-section comprehensive guide
5. Includes roadmap, metrics, team structure (genericized)
6. Saves with full structure ready for refinement

## Configuration

### Required
None! Works out-of-the-box with vault access.

### Optional (Enhanced Research)

**Readwise Integration:**
```bash
export READWISE_API_KEY=your_readwise_api_token
```
Enables pulling highlights and annotations.

**Brand Voice Customization:**
Edit `.opencode/brand/hacker1db-voice.md` to adjust:
- Voice characteristics
- Security filter patterns
- Content structure preferences
- Code example style

## Tips

1. **Be Specific**: "API Security" → Better: "REST API Authentication Patterns"
2. **Use Your Learning**: Command prioritizes your vault notes for authentic voice
3. **Review Research Sources**: Check the comment section to see what was used
4. **Add Personal Touch**: Generated draft is foundation—add your unique experiences
5. **Refine Code Examples**: Verify code works and matches your preferred style

## Troubleshooting

**No vault notes found**
→ Topic might be too niche; try broader terms first
→ Check vault structure matches expected paths

**Readwise highlights not included**
→ Verify `READWISE_API_KEY` is set: `echo $READWISE_API_KEY`
→ Check highlights are tagged with relevant keywords

**Generated content too generic**
→ Add more personal notes to vault on the topic
→ Edit draft to include your specific experiences

**Security filters too aggressive**
→ Review `.opencode/brand/hacker1db-voice.md`
→ Adjust filter patterns as needed

**Draft file not created**
→ Ensure you're in vault directory: `pwd`
→ Check permissions on `2.Areas/Personal Home/Blog Posts 🕸/`

## Advanced Usage

### Research Multiple Related Topics
```
/blogresearcher Container Security Fundamentals
/blogresearcher Kubernetes Security Best Practices
/blogresearcher Docker Image Hardening
```

Creates series of related posts with internal linking opportunities.

### Series Planning
```
/blogresearcher Building a DevSecOps Program Part 1 Strategy
/blogresearcher Building a DevSecOps Program Part 2 Tooling
/blogresearcher Building a DevSecOps Program Part 3 Culture
```

Generates multi-part series with consistent structure.

## What Makes This Different?

**Traditional Blog Writing:**
- Start with blank page
- Research manually
- Copy/paste from multiple sources
- Forget to filter sensitive info
- Inconsistent voice

**With /blogresearcher:**
- ✅ Automated research across 3 sources (vault, Readwise, online)
- ✅ Your authentic voice (uses your notes as primary source)
- ✅ Security filtering automatic
- ✅ Consistent structure
- ✅ Ready in seconds, not hours

## Example Topics to Try

**DevSecOps:**
```
/blogresearcher Shifting Security Left in CI/CD
/blogresearcher SAST vs DAST Which to Use When
/blogresearcher Building Security Gates That Developers Love
```

**Application Security:**
```
/blogresearcher Common Authentication Vulnerabilities
/blogresearcher Preventing SQL Injection in Modern Apps
/blogresearcher API Rate Limiting Best Practices
```

**Cloud Security:**
```
/blogresearcher Securing Kubernetes RBAC
/blogresearcher Container Image Scanning Strategies
/blogresearcher Secret Management in Microservices
```

**Security Culture:**
```
/blogresearcher Teaching Developers to Think Like Attackers
/blogresearcher Building a Security Champions Program
/blogresearcher Making Security Reviews Non-Blocking
```

---

**Start here:**
```
/blogresearcher [Your Topic]
```

The command will:
1. ✅ Search your vault for related notes
2. ✅ Pull relevant Readwise highlights (if configured)
3. ✅ Research current best practices online
4. ✅ Synthesize into cohesive blog post
5. ✅ Apply security filters automatically
6. ✅ Match hacker1db.dev brand voice
7. ✅ Save to `2.Areas/Personal Home/Blog Posts 🕸/` with `draft: true`

Open in Obsidian, review, refine, publish. 🚀
