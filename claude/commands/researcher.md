---
description: Research new application security vulnerabilities from this week using CISA KEV, Readwise, and web sources, then append findings to today's Obsidian daily note
---
Research only the **latest vulnerabilities that came out this week**. Focus on new CVEs, zero-days, and actively exploited vulnerabilities. Output findings to the Obsidian daily note.

## ⚠️ SECURITY NOTICE
**CRITICAL:** The Readwise API token must NEVER be displayed, echoed, logged, or shown in any output. Handle the `$READWISE_TOKEN` variable with strict confidentiality.

## Step 1: Get Readwise API Key

```bash
READWISE_TOKEN=$(op item get 37nc3retjhuxh6qafon4b65i6q --reveal --fields apikey 2>/dev/null)
if [ -z "$READWISE_TOKEN" ]; then
    echo "❌ Failed to retrieve API key from 1Password"
    exit 1
else
    echo "✅ API key retrieved successfully"
fi
```

**CRITICAL: Never display, echo, or log the $READWISE_TOKEN variable**

## Step 2: Search Readwise Reader (Recent Articles Only)

Query Readwise for articles from the **last 7 days** about security vulnerabilities:

```bash
curl -s -H "Authorization: Token $READWISE_TOKEN" \
     "https://readwise.io/api/v3/list/?location=new&category=article&query=vulnerability CVE security" | \
     jq '.results[] | select(.created_at > (now - 604800)) | {title, url, author, created_at, id, reader_url}'
```

For each article, capture: `id`, `reader_url`, `url`, `title`, `author`, `created_at`

Filter for: CVE-YEAR-*, "zero-day", "actively exploited", "recently disclosed"

## Step 3: Web Research (NEW Vulnerabilities Only)

Search specifically for vulnerabilities from **this week**:
1. "CVE [current month] [current year] week"
2. "zero day vulnerability [current date]"
3. "CISA KEV added this week"
4. "actively exploited vulnerability [current year]"
5. "critical vulnerability disclosed [current month] [current year]"

**Required Sources:** CISA KEV Catalog, security vendor blogs, CVE database (last 7 days)

**CRITICAL FILTERING:**
- Ignore anything older than 7 days
- Prioritize vulnerabilities with active exploitation
- Focus on Critical/High severity only

## Step 4: Format Output

```markdown
### [TIME] - This Week's NEW Vulnerabilities

> [!warning] Week of [date range]
> X new critical vulnerabilities | Y actively exploited | Z zero-days

#### 🔴 Critical New Vulnerabilities

**CVE-YEAR-XXXXX** (Discovered: [date])
- **Affected:** [Product/Vendor]
- **Severity:** Critical (CVSS X.X)
- **Status:** Actively Exploited / PoC Available / Patch Available
- **Impact:** [Brief description]
- **Action Required:** [What to do]
- **Source:** [URL]

#### 📊 This Week's Statistics
#### 🎯 Immediate Actions
#### 📚 From Readwise Reader (This Week)

**Note:** Use Readwise Reader links (not original source URLs):
`[Read in Readwise →](https://readwise.io/reader/document/DOCUMENT_ID)`

#security #vulnerabilities #weekly-update #cve #readwise
```

## Step 5: Append to Daily Note

```bash
VAULT_PATH="$HOME/notes/SecondBrain"
DAILY_NOTES_PATH="$VAULT_PATH/0.Quick Notes 📨/Daily Stuff"
TODAY=$(date +%Y-%m-%d)
DAILY_NOTE="$DAILY_NOTES_PATH/$TODAY.md"
```

## Security & Cleanup

```bash
unset READWISE_TOKEN
echo "✅ Session cleaned up securely"
```

**Token Security Rules:**
- Token retrieved via 1Password CLI only
- Token never echoed, printed, or logged
- Token cleared from memory after use
- No verbose flags that would expose headers
