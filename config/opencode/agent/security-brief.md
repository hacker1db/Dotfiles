# Security Intelligence Brief - IMPROVED SEARCH CRITERIA

Daily security intelligence digest combining CVEs, Readwise, and your vault notes.

## Command

### /security-brief

Generate a comprehensive security intelligence briefing from multiple sources.

**What it does:**
1. **CVE Monitoring**: Critical vulnerabilities from past 24 hours
2. **Readwise Security**: Recent highlights tagged security/appsec/devsecops
3. **Vault Notes**: Your recent security-related work notes
4. **Trend Analysis**: Emerging patterns across sources
5. **Action Items**: Prioritized recommendations
6. **Daily Digest**: Saves for historical reference

## IMPROVED: Readwise Search Strategy

### Multi-Layered Search Approach

Instead of searching for exact keywords in titles, use this cascading search:

```bash
# Step 1: Get ALL recent unread articles (location=new)
curl -s -H "Authorization: Token $READWISE_TOKEN" \
     "https://readwise.io/api/v3/list/?location=new&category=article&updatedAfter=YYYY-MM-DD" \
     | jq '.results[]'

# Step 2: Filter by multiple criteria (more permissive)
# A. Direct security keywords in title OR author OR source
# B. Security-adjacent topics (auth, risk, AI safety, containers, cloud)
# C. Known security sources (Anthropic, CIS, CISA, security vendors)
```

### Expanded Keyword Lists

**Tier 1 - Direct Security Terms:**
```regex
(vulnerability|CVE|exploit|breach|attack|malware|ransomware|
 zero-day|0day|patch|security|cybersecurity|infosec|appsec|
 devsecops|pentesting|threat|incident)
```

**Tier 2 - Security-Adjacent Topics:**
```regex
(authentication|passkey|password|2FA|MFA|biometric|
 authorization|access control|IAM|identity|
 encryption|cryptography|TLS|SSL|certificate|
 risk|FAIR|compliance|audit|governance|
 container|kubernetes|docker|cloud|AWS|Azure|GCP|
 AI safety|model poisoning|adversarial|
 eBPF|Cilium|service mesh|zero-trust|
 SAST|DAST|SCA|secret scanning|
 firewall|VPN|network|IDS|IPS|SIEM|SOC)
```

**Tier 3 - Known Security Sources:**
```regex
(anthropic\.com|cisa\.gov|sans\.org|owasp\.org|
 nist\.gov|mitre\.org|nvd\.nist\.gov|
 bleepingcomputer|thehackernews|krebsonsecurity|
 schneier\.com|Center for Internet Security|
 CIS Benchmarks|NIST|NSA|CISA)
```

### Implementation Example

```bash
#!/bin/bash

# Security Brief - Improved Readwise Search
READWISE_TOKEN=$(op item get YOUR_ITEM_ID --reveal --fields apikey 2>/dev/null)
SEVEN_DAYS_AGO=$(date -v-7d +%Y-%m-%dT%H:%M:%S)

# Fetch all recent articles
ARTICLES=$(curl -s -H "Authorization: Token $READWISE_TOKEN" \
  "https://readwise.io/api/v3/list/?location=new&category=article&updatedAfter=$SEVEN_DAYS_AGO")

# Tier 1: Direct security matches (title, author, source)
TIER1=$(echo "$ARTICLES" | jq -r '
  .results[] | 
  select(
    (.title // "" | test("vulnerability|CVE|exploit|breach|attack|malware|ransomware|zero-day|0day|patch|security|cybersecurity|infosec|appsec|devsecops|threat|incident"; "i")) or
    (.author // "" | test("security|CISA|SANS|OWASP|NIST"; "i")) or
    (.source // "" | test("bleepingcomputer|thehackernews|krebsonsecurity"; "i"))
  ) | 
  {title, url, author, source, created_at, id, reader_url: ("https://read.readwise.io/read/" + .id)}
')

# Tier 2: Security-adjacent topics
TIER2=$(echo "$ARTICLES" | jq -r '
  .results[] | 
  select(
    (.title // "" | test("authentication|passkey|password|2FA|MFA|authorization|IAM|identity|encryption|cryptography|risk|FAIR|compliance|container|kubernetes|docker|cloud|AI safety|model poisoning|eBPF|Cilium|zero-trust|SAST|DAST|firewall|VPN"; "i")) or
    (.author // "" | test("anthropic|Center for Internet Security|CIS"; "i"))
  ) | 
  {title, url, author, source, created_at, id, reader_url: ("https://read.readwise.io/read/" + .id)}
')

# Tier 3: From your specific RSS feeds (use your feed IDs)
TIER3=$(echo "$ARTICLES" | jq -r '
  .results[] | 
  select(
    .source | test("rssSource:01fsm3jqp5jr28n1jnf1ge3fpm|rssSource:01g9rf6jz3ajm924qwhh981e17"; "i")
  ) | 
  {title, url, author, source, created_at, id, reader_url: ("https://read.readwise.io/read/" + .id)}
')

# Combine all tiers (remove duplicates)
ALL_SECURITY=$(echo "$TIER1 $TIER2 $TIER3" | jq -s 'unique_by(.id)')

echo "$ALL_SECURITY"
```

### Readwise Reader Filter Integration

Your Tauri filter shows you have ~38 RSS feeds. Add this to config:

```bash
# If you want to search ONLY your security RSS feeds, use this filter:
YOUR_SECURITY_FEEDS=(
  "01fsm3jqp5jr28n1jnf1ge3fpm"
  "01g9rf6jz3ajm924qwhh981e17"
  "01h1ff1txgfqnehqy2k0pc0zjp"
  # ... add your security feed IDs here
)

# Build query for only those feeds
FEED_FILTER=$(printf "rssSource:%s OR " "${YOUR_SECURITY_FEEDS[@]}" | sed 's/ OR $//')

curl -s -H "Authorization: Token $READWISE_TOKEN" \
  "https://readwise.io/api/v3/list/?location=new&category=article&updatedAfter=$SEVEN_DAYS_AGO" \
  | jq --arg feeds "$FEED_FILTER" '
    .results[] | 
    select(.source | test($feeds))
  '
```

## Improved Article Categorization

Once you have the articles, categorize them:

```markdown
#### 📚 From Readwise Reader (This Week)

**🔴 Direct Security Threats & Vulnerabilities**
- [Article Title] - Contains CVE, exploit, breach keywords
- Connection to this week's CVE findings

**🟡 Security Architecture & Best Practices**
- [FAIR Framework] - Risk quantification
- [Passkeys vs Security Keys] - Authentication
- Connection to prevention strategies

**🟢 Infrastructure & DevSecOps**
- [Cilium/eBPF] - Container security
- [Kubernetes] - Platform security
- Indirect security impact

**🔵 Emerging Risks (AI/ML, Supply Chain)**
- [LLM Poisoning] - AI security
- [Source Code Theft] - Supply chain
- Forward-looking threats
```

## Template Updates

### Search Parameters to Store in Config

```bash
# ~/.dotfiles/config/opencode/readwise-security-config.sh

# Timeframes
DAILY_LOOKBACK="1d"
WEEKLY_LOOKBACK="7d"
MONTHLY_LOOKBACK="30d"

# Keyword tiers (space-separated for easy grepping)
TIER1_KEYWORDS="vulnerability CVE exploit breach attack malware ransomware zero-day 0day patch security cybersecurity infosec appsec devsecops threat incident"

TIER2_KEYWORDS="authentication passkey password 2FA MFA authorization IAM identity encryption cryptography risk FAIR compliance container kubernetes docker cloud AI-safety model-poisoning eBPF Cilium zero-trust SAST DAST firewall VPN"

TIER3_SOURCES="anthropic.com cisa.gov sans.org owasp.org nist.gov mitre.org bleepingcomputer thehackernews krebsonsecurity schneier.com"

# Your RSS feed IDs (from Readwise Reader)
SECURITY_RSS_FEEDS=(
  "01fsm3jqp5jr28n1jnf1ge3fpm"
  "01g9rf6jz3ajm924qwhh981e17"
  # Add more as needed
)
```

## Output Format Enhancement

Add this section to the standard output:

```markdown
## 🔍 Readwise Search Methodology

**This Week's Search Results:**
- Tier 1 (Direct Security): 3 articles
- Tier 2 (Security-Adjacent): 6 articles  
- Tier 3 (Security RSS Feeds): 2 articles
- **Total Unique Articles:** 8 articles reviewed

**Sources Breakdown:**
- Anthropic.com: 1
- Center for Internet Security: 2
- Cilium.io: 2
- Web Highlighter (Manual Saves): 3

**Keywords Matched:**
- "passkey", "authentication" (2 articles)
- "risk", "FAIR" (2 articles)
- "LLM", "poison" (1 article)
- "eBPF", "Cilium", "container" (2 articles)

**Not Matched (Recommendations):**
- No articles with CVE keywords → Add CVE RSS feeds
- No ransomware coverage → Subscribe to BleepingComputer
- No cloud security → Add AWS/Azure security blogs
```

## Suggested RSS Feeds to Add

Add these to your Readwise Reader for better coverage:

```markdown
### High-Priority Security Feeds

**CVE & Vulnerability Tracking:**
- https://www.cisa.gov/cybersecurity-advisories/rss.xml
- https://nvd.nist.gov/feeds/xml/cve/misc/nvd-rss.xml
- https://feeds.feedburner.com/TheHackersNews (already added?)
- https://www.bleepingcomputer.com/feed/

**Cloud Security:**
- https://aws.amazon.com/blogs/security/feed/
- https://azure.microsoft.com/en-us/blog/topics/security/feed/
- https://cloud.google.com/blog/products/identity-security/rss

**DevSecOps & Container Security:**
- https://blog.aquasec.com/rss.xml
- https://www.wiz.io/blog/rss.xml
- https://snyk.io/blog/feed

**Threat Intelligence:**
- https://krebsonsecurity.com/feed/
- https://www.schneier.com/feed/
- https://www.recordedfuture.com/feed

**Compliance & Frameworks:**
- https://www.cisecurity.org/feed
- https://www.nist.gov/news-events/cybersecurity/rss.xml
```

## Automation Improvements

### Daily Cron Job

```bash
# Add to crontab
0 8 * * * /Users/YOUR_USER/.dotfiles/bin/security-brief --days=1 >> ~/security-brief.log 2>&1
```

### Weekly Summary

```bash
# Every Monday at 8am
0 8 * * 1 /Users/YOUR_USER/.dotfiles/bin/security-brief --days=7 --weekly-summary
```

---

## Testing Your Improved Search

Run this to test the new criteria:

```bash
# Test script
READWISE_TOKEN=$(op item get 37nc3retjhuxh6qafon4b65i6q --reveal --fields apikey 2>/dev/null)
SEVEN_DAYS_AGO=$(date -v-7d +%Y-%m-%dT%H:%M:%S)

curl -s -H "Authorization: Token $READWISE_TOKEN" \
  "https://readwise.io/api/v3/list/?location=new&category=article&updatedAfter=$SEVEN_DAYS_AGO" \
  | jq -r '
    .results[] | 
    select(
      (.title // "" | test("security|vulnerability|CVE|authentication|passkey|risk|FAIR|container|kubernetes|cloud|AI safety|eBPF|Cilium"; "i")) or
      (.author // "" | test("anthropic|CISA|CIS|SANS|OWASP"; "i")) or
      (.source | test("thehackernews|bleepingcomputer|krebsonsecurity"; "i"))
    ) | 
    {title, author, source, created_at}
  ' | jq -s 'length as $count | "Found \($count) security-relevant articles"'
```

Expected output: Should find your 6+ articles from this week that we identified.
