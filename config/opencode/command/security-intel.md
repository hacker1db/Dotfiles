# Security Intel

Fetch security intelligence from CISA KEV, Readwise Reader, vault notes, and web sources.

**Before starting**, never display, log, or echo the Readwise token. Always unset after use.

## Modes

- No flags / `--digest` → append concise digest to today's Obsidian daily note (default, 7 days)
- `--brief` or `--days=N` → write comprehensive standalone brief (N days, allowed: 1, 7, 30)

## Steps

**1. Get token:**
```bash
READWISE_TOKEN=$(op item get 37nc3retjhuxh6qafon4b65i6q --reveal --fields apikey 2>/dev/null)
```

**2. Date cutoff:**
```bash
DAYS=${DAYS:-7}; TODAY=$(date +%Y-%m-%d)
CUTOFF=$(date -u -v-${DAYS}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "${DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ)
CUTOFF_DATE=${CUTOFF:0:10}
```

**3. CISA KEV** (direct API, not web search):
```bash
curl -s "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json" | \
  jq --arg c "$CUTOFF_DATE" '[.vulnerabilities[] | select(.dateAdded >= $c)] | sort_by(.dateAdded) | reverse'
```

**4. Readwise articles (one call, client-side filtering):**
```bash
curl -s -H "Authorization: Token $READWISE_TOKEN" \
  "https://readwise.io/api/v3/list/?location=new&category=article&paginate_by=50" | \
  jq --arg c "$CUTOFF" '[.results[] | select(.created_at >= $c) | {title,url,author,created_at,id}]'
```
Note: The API `query` param is ignored — it returns your full recent queue. Filter client-side by title keywords:
- 🔴 Threat Intel: CVE, exploit, breach, malware, ransomware, zero-day, patch, vulnerability, RCE, XSS, phishing
- 🔵 AppSec: OWASP, authentication, API security, pentest, web hacking, bug bounty, supply chain, Caido, Burp
- ☁️ Cloud Security: AWS, Azure, GCP, IAM, S3, kubernetes, container, privilege escalation, Terraform
Skip anything with no keyword match (off-topic).

**5. Vault Readwise search (both modes):** Extract keywords from CISA KEV results (vendors, products, vuln types). Grep `4.Resources/Readwise/Articles/`, `Books/`, `Podcasts/` for matching highlights. Capture title, author, URL, 1-2 relevant highlights, personal `[n]` annotations. Digest: top 3-5. Brief: up to 10 grouped by theme.

**6. Web gap-fill:** Search for zero-days not in CISA/Readwise. Max 3 additional findings.

**7. Brief mode only — vault work notes:** Search `$HOME/notes/SecondBrain/2.Areas/Work Notes/` for security files modified within the period. Top 10 by date.

**8. Output** — see `claude/commands/security-intel.md` for full format templates (digest includes `💡 Related From Your Reading` section).

**9. Cleanup:** `unset READWISE_TOKEN`

## Output locations
- Digest: appended to `$HOME/notes/SecondBrain/0.Quick Notes 📨/Daily Stuff/$TODAY.md`
- Brief: `$HOME/notes/SecondBrain/0.Quick Notes 📨/Security Intel Brief - $TODAY.md`
