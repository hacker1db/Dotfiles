---
name: security-brief
description: Generates a structured security intelligence brief combining CISA KEV feed, Readwise security highlights, and vault notes with tiered classification and actionable recommendations
model: claude-opus-4-6
---

Accept optional flag: `--days=N` (default 1, allowed: 1, 7, 30)

## Tasks

1. Determine period start by subtracting N days from now (UTC ISO start stamp for API filters)
2. Gather data sources:
   - CISA Known Exploited Vulnerabilities JSON feed (new entries where dateAdded >= period start)
   - Readwise Reader articles added/updated after period start (use secure token; never display value)
   - Obsidian vault recent security note updates (markdown files under Work Notes path matching security keywords, modified within N days)
3. Classify Readwise articles into tiers:
   - **Tier 1 Direct**: CVE|exploit|breach|attack|malware|ransomware|zero-day|patch|vulnerability
   - **Tier 2 Adjacent**: authentication|passkey|risk|FAIR|compliance|encryption|container|kubernetes|cloud|identity|IAM|eBPF|Cilium|AI safety
   - **Tier 3 Sources**: anthropic|cisa|sans|owasp|nist|bleepingcomputer|thehackernews|krebsonsecurity|schneier
4. Build sections in order with concise prioritized bullets

## Output Format

```markdown
## 🔒 Security Intelligence Brief - {Daily|Weekly|Monthly}

*Generated: [timestamp] | Coverage: past N day(s)*

### 🚨 Critical CVEs
[CVE, vendor/product, dateAdded, ransomware flag, action line]

### 📊 High-Priority Vulnerability Themes
[Group counts, ransomware summary]

### 📝 Recent Personal Security Notes
[Top 10 updated note names with modified date]

### 📚 Readwise Security Highlights
[title, source, added date; one relevance sentence]

### 🎯 Trend Analysis
[Most targeted vendor, reading focus themes, work note focus, alignment check]

### ✅ Recommended Actions
**Immediate (today):** [patch tasks from CVEs]
**This Week:** [...]
**This Month:** [strategic]

### 📅 Next Brief: [date]

---
#security #intelligence #cve #threat-analysis #{daily|weekly|monthly}
```

## Security Rules

- Never print secret tokens
- Use HTTPS only
- Clear sensitive variables after use

## Prioritization

- Sort CVEs newest first
- Limit articles to 20
- Limit notes to 10

## Readwise Search Strategy

Retrieve token via: `op item get 37nc3retjhuxh6qafon4b65i6q --reveal --fields apikey`

Use cascading tier search:
```bash
# Fetch all recent articles
curl -s -H "Authorization: Token $READWISE_TOKEN" \
  "https://readwise.io/api/v3/list/?location=new&category=article&updatedAfter=$PERIOD_START"

# Apply tier filters using jq
# Tier 1: Direct security terms in title/author/source
# Tier 2: Security-adjacent topics
# Tier 3: Known security RSS feed sources
```

Combine all tiers, remove duplicates by ID.
