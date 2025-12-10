---
description: Generate structured security intelligence brief
agent: security-brief
---
Accept optional flag: --days=N (default 1, allowed: 1,7,30)
Tasks:
1. Determine period start by subtracting N days from now (UTC ISO start stamp for API filters)
2. Gather data sources:
   - CISA Known Exploited Vulnerabilities JSON feed (new entries where dateAdded >= period start)
   - Readwise Reader articles added/updated after period start (use secure token; never display value)
   - Obsidian vault recent security note updates (markdown files under Work Notes path matching security keywords, modified within N days)
3. Classify Readwise articles into tiers:
   - Tier1 Direct: CVE|exploit|breach|attack|malware|ransomware|zero-day|patch|vulnerability
   - Tier2 Adjacent: authentication|passkey|risk|FAIR|compliance|encryption|container|kubernetes|cloud|identity|IAM|eBPF|Cilium|AI safety
   - Tier3 Sources: anthropic|cisa|sans|owasp|nist|bleepingcomputer|thehackernews|krebsonsecurity|schneier
4. Build sections in order with concise prioritized bullets:
   A. Critical CVEs (each: CVE, vendor/product, dateAdded, ransomware flag, action line)
   B. High-Priority Vulnerability Themes (group counts, ransomware summary)
   C. Recent Personal Security Notes (top 10 updated note names with modified date)
   D. Readwise Security Highlights (title, source, added date; one relevance sentence)
   E. Trend Analysis (Most targeted vendor, reading focus themes, work note focus, alignment check)
   F. Recommended Actions (Immediate today: patch tasks from CVEs; This Week; This Month strategic)
   G. Next Brief (based on days: +1d, +7d, +30d)
Output Format (markdown headings):
## 🔒 Security Intelligence Brief - {Daily|Weekly|Monthly}
Meta lines: Generated timestamp, Coverage: past N day(s)
Section headings use emojis: 🚨, 📊, 📝, 📚, 🎯, ✅, 📅
Security rules:
- Never print secret tokens
- Use HTTPS only
- Clear sensitive variables after use
Prioritization:
- Sort CVEs newest first
- Limit articles to 20
- Limit notes to 10
End with tags line: #security #intelligence #cve #threat-analysis #{daily|weekly|monthly}
