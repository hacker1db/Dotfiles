---
description: "Pull this week's security intelligence from CISA KEV, Readwise, and the web, then output it as a quick daily digest or a full brief. Use when you want to catch up on new CVEs, check what's been actively exploited, run a daily security update, generate a weekly threat report, or get a security intelligence brief. Triggers on: \"vuln digest\", \"security brief\", \"what CVEs came out this week\", \"threat intel\", \"check CISA KEV\", \"security update\", \"weekly security review\"."
---

Fetch security intelligence from CISA KEV, Readwise Reader, and web sources, then output it as a digest or brief.

**Mode is determined by flags or context:**
- No flags / `--digest` → quick digest appended to today's Obsidian daily note (default, 7 days)
- `--brief` or `--days=N` → comprehensive standalone brief (N days, default 7; allowed: 1, 7, 30)

## ⚠️ Token Security
The Readwise token must never be displayed, echoed, logged, or shown in output. Unset after use.

---

## Step 1: Get Readwise Token

```bash
READWISE_TOKEN=$(op item get 37nc3retjhuxh6qafon4b65i6q --reveal --fields apikey 2>/dev/null)
[ -z "$READWISE_TOKEN" ] && echo "❌ Could not retrieve token from 1Password" && exit 1
```

## Step 2: Compute Date Cutoff

```bash
DAYS=${DAYS:-7}
TODAY=$(date +%Y-%m-%d)
# macOS and Linux compatible
CUTOFF=$(date -u -v-${DAYS}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "${DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ)
CUTOFF_DATE=${CUTOFF:0:10}   # YYYY-MM-DD for CISA comparison
```

## Step 3: Fetch CISA KEV Additions

Call the official feed — do not web search for it:

```bash
curl -s "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json" | \
  jq --arg cutoff "$CUTOFF_DATE" \
    '[.vulnerabilities[] | select(.dateAdded >= $cutoff) | {
       cveID, vendorProject, product, vulnerabilityName,
       dateAdded, shortDescription, requiredAction, dueDate
     }] | sort_by(.dateAdded) | reverse'
```

If empty: note "No new CISA KEV additions in this period."

## Step 4: Fetch Readwise Recent Articles

One API call returns your full recent queue (the `query` param is ignored by the API — filtering is done client-side):

```bash
curl -s -H "Authorization: Token $READWISE_TOKEN" \
  "https://readwise.io/api/v3/list/?location=new&category=article&paginate_by=50" | \
  jq --arg cutoff "$CUTOFF" \
    '[.results[] | select(.created_at >= $cutoff) | {title, url, author, created_at, id}]'
```

**Client-side: categorize by title keywords into three buckets:**
- **🔴 Threat Intel** — CVE, exploit, breach, attack, malware, ransomware, zero-day, patch, vulnerability, RCE, injection, XSS, phishing, backdoor
- **🔵 AppSec** — OWASP, authentication, auth bypass, API security, pentest, web hacking, bug bounty, security testing, Caido, Burp, supply chain
- **☁️ Cloud Security** — AWS, Azure, GCP, IAM, S3, bucket, container, kubernetes, k8s, privilege escalation, cloud misconfiguration, Terraform, infrastructure

Assign each article to its most specific matching bucket. Skip anything clearly off-topic (lifestyle, news, non-security dev tools). An article with no keyword match in any bucket is skipped.

## Step 5: Search Vault Readwise Highlights (Both Modes)

After getting CISA KEV data, extract the key themes — vendor names, product names, vulnerability types (e.g., "Chrome", "Ivanti", "authentication bypass", "deserialization", "RCE"). Then search your saved Readwise vault files for highlights that match those themes. This surfaces what you've previously read and annotated that's relevant to today's threats.

Search these vault directories:
- `$HOME/notes/SecondBrain/4.Resources/Readwise/Articles/`
- `$HOME/notes/SecondBrain/4.Resources/Readwise/Books/`
- `$HOME/notes/SecondBrain/4.Resources/Readwise/Podcasts/`

Each file has an `## Highlights` section with blockquoted excerpts. Personal notes are marked `[n]` — these are your own annotations and are especially valuable.

**Strategy:**
1. Extract keywords from CISA KEV results (vendors, products, vuln types, attack patterns)
2. Use Grep to search filenames and file contents for those keywords
3. For each matching file: read the relevant highlights only
4. Capture: title, author, URL, 1-2 most relevant highlights, any `[n]` personal notes

**Digest mode:** Top 3-5 most relevant matches.
**Brief mode:** Up to 10 matches, grouped by theme.

## Step 6: Web Search Gap-Fill (Targeted)

Search for vulnerabilities not covered by CISA or Readwise:
- `"zero-day" OR "0-day" CVE site:thehackernews.com OR site:bleepingcomputer.com`
- `"actively exploited" CVE [current month year]`

Limit: 3 findings max. Skip duplicates already in CISA.

**In brief mode only — also check vault work notes:**
Search `$HOME/notes/SecondBrain/2.Areas/Work Notes/DevSecOps Notes/` and `AppSec Notes/` for markdown files modified within the period that contain security keywords. Capture top 10 by modified date.

## Step 7: Build Output

---

### DIGEST MODE output (append to daily note)

```markdown
---

### 🛡️ Security Intel — [TODAY]

> [!warning] Week of [CUTOFF_DATE] → [TODAY]
> [N] CISA KEV | [T] threat intel | [A] appsec | [C] cloud articles | [V] vault highlights | [K] web findings

#### 🔴 CISA KEV — New This Period

**[CVE-ID]** — [vendorProject] [product]
- **Added:** [dateAdded] | **Due:** [dueDate]
- **What:** [vulnerabilityName] — [shortDescription]
- **Fix:** [requiredAction]

#### 📚 Readwise — Security Reading This Week

**🔴 Threat Intel**
- [title] — [author] | [url]

**🔵 AppSec**
- [title] — [author] | [url]

**☁️ Cloud Security**
- [title] — [author] | [url]

*(Use the article's original URL if reader_url is null. Omit a category section entirely if no articles match it.)*

#### 💡 Related From Your Reading

*(Highlights from your saved Readwise content that relate to this week's threats — surfaces what you already know)*

- **[article/book title]** — [author]
  > [relevant highlight]
  *Your note:* [personal [n] annotation if present]

#### 🌐 Additional Findings

- **[CVE or finding]** — [brief description] — [source URL]

#### 🎯 Immediate Actions

*(Top 2-3 concrete actions: patch X, review Y, monitor Z)*

#security #cve #security-intel
```

Check for duplicate before appending:
```bash
VAULT="$HOME/notes/SecondBrain"
DAILY_NOTE="$VAULT/0.Quick Notes 📨/Daily Stuff/$TODAY.md"
[ ! -f "$DAILY_NOTE" ] && printf "# %s\n\n" "$TODAY" > "$DAILY_NOTE"
grep -q "Security Intel — $TODAY" "$DAILY_NOTE" && echo "⚠️ Already appended today — skipping" && unset READWISE_TOKEN && exit 0
```

**Important:** When appending the digest, use `printf` or `tee -a` with a variable rather than a heredoc — `$HOME` does not expand inside heredoc delimiters when quoted. Example:
```bash
printf '%s\n' "$DIGEST_CONTENT" >> "$DAILY_NOTE"
```

---

### BRIEF MODE output (standalone file)

Write to: `$HOME/notes/SecondBrain/0.Quick Notes 📨/Security Intel Brief - [TODAY].md`

```markdown
## 🔒 Security Intelligence Brief — {Daily|Weekly|Monthly}

> Generated: [timestamp] | Coverage: past [N] day(s)

### 🚨 Critical CVEs

**[CVE-ID]** — [vendor/product] — Added [dateAdded] [🔴 Ransomware] if applicable
- [shortDescription]
- **Action:** [requiredAction] by [dueDate]

### 📊 Vulnerability Themes

*(Group CVEs by vendor/type, show counts, summarize ransomware involvement)*

### 📝 Personal Security Notes (Updated This Period)

- [note name] — modified [date]

### 📚 Readwise Security Highlights

**Tier 1 — Direct Threats:**
- [title] — [source] — [added date] | [one relevance sentence]

**Tier 2 — Adjacent Topics:**
- [title] — [source] — [added date] | [one relevance sentence]

**Tier 3 — Trusted Sources:**
- [title] — [source] — [added date] | [one relevance sentence]

### 🎯 Trend Analysis

- Most targeted vendor this period: [vendor]
- Reading focus themes: [top 3 themes from Readwise]
- Work notes focus: [top topics from vault]

### ✅ Recommended Actions

**Immediate (Today):** [patch tasks from CVEs]
**This Week:** [monitoring and review tasks]
**This Month:** [strategic items]

### 📅 Next Brief

[Suggest next run date based on --days value]

#security #intelligence #cve #threat-analysis #{daily|weekly|monthly}
```

---

## Step 8: Cleanup

```bash
unset READWISE_TOKEN
echo "✅ Done"
```
