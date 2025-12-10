---
description: Research NEW application security vulnerabilities from this week
mode: subagent
permission:
  edit: allow
  bash: ask
  webfetch: allow
---

# Task: Find This Week's NEW Security Vulnerabilities

Research only the **latest vulnerabilities that came out this week**. Focus on new CVEs, zero-days, and actively exploited vulnerabilities. Output findings to my Obsidian daily note.

## ⚠️ SECURITY NOTICE
**CRITICAL:** The Readwise API token must NEVER be displayed, echoed, logged, or shown in any output. Handle the `$READWISE_TOKEN` variable with strict confidentiality.

## Current Date Context
- Today: Monday, October 20, 2025
- **Focus timeframe: October 14-20, 2025 (this week)**
- Only include vulnerabilities disclosed/discovered in the last 7 days

## Step 1: Get Readwise API Key

```bash
# Retrieve token securely (never echo or display)
READWISE_TOKEN=$(op item get 37nc3retjhuxh6qafon4b65i6q --reveal --fields apikey 2>/dev/null)

# Verify retrieval without showing token
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
# Search for recent security articles (silent mode - no verbose output)
curl -s -H "Authorization: Token $READWISE_TOKEN" \
     "https://readwise.io/api/v3/list/?location=new&category=article&query=vulnerability CVE security" | \
     jq '.results[] | select(.created_at > (now - 604800)) | {title, url, author, created_at, id, reader_url}'

# Note: Use -s (silent) flag to prevent curl from showing request details
# NEVER use -v (verbose) as it would display the Authorization header
```

**IMPORTANT:** For each article, capture:
- `id` - Document ID for Readwise Reader URL
- `reader_url` - Direct link to article in Readwise Reader (e.g., `https://readwise.io/reader/document/DOCUMENT_ID`)
- `url` - Original source URL (for reference)
- `title`, `author`, `created_at` - Metadata

Filter for articles containing:
- CVE-2025-* (2025 vulnerabilities only)
- "zero-day" or "0-day"
- "actively exploited"
- "this week" or "recently disclosed"

### Optional: Get Highlights from Articles

For articles with highlights, retrieve them to add context:

```bash
# Get highlights for a specific document
curl -s -H "Authorization: Token $READWISE_TOKEN" \
     "https://readwise.io/api/v3/highlights/?document_id=DOCUMENT_ID" | \
     jq '.results[] | {text, highlighted_at, url}'
```

Include highlights in the output to show what you found important when reading.

## Step 3: Web Research (NEW Vulnerabilities Only)

Search the web specifically for vulnerabilities from **this week**:

### Priority Searches:
1. "CVE October 2025 week" - This week's CVEs
2. "zero day vulnerability october 20 2025" - Latest zero-days
3. "CISA KEV added this week" - New CISA additions
4. "actively exploited vulnerability 2025" - Current exploitation
5. "critical vulnerability disclosed october 2025" - Recent disclosures

### Required Sources:
- CISA Known Exploited Vulnerabilities Catalog (filter by date added)
- Security vendor blogs (dated this week)
- CVE database (published_date: last 7 days)
- Security researcher Twitter/feeds (this week)

### CRITICAL FILTERING:
- **Ignore** anything older than October 14, 2025
- **Prioritize** vulnerabilities with active exploitation
- **Focus** on Critical/High severity only
- **Skip** theoretical or low-severity findings

## Step 4: Format Output for Obsidian

Create a concise report with:

```markdown
### [TIME] - This Week's NEW Vulnerabilities

> [!warning] Week of October 14-20, 2025
> X new critical vulnerabilities | Y actively exploited | Z zero-days

#### 🔴 Critical New Vulnerabilities

**CVE-2025-XXXXX** (Discovered: Oct XX, 2025)
- **Affected:** [Product/Vendor]
- **Severity:** Critical (CVSS X.X)
- **Status:** Actively Exploited / PoC Available / Patch Available
- **Impact:** [Brief description]
- **Action Required:** [What to do]
- **Source:** [URL]

---

#### 📊 This Week's Statistics
- New CVEs: X
- Zero-days: X
- CISA KEV additions: X
- Critical severity: X

#### 🎯 Immediate Actions
- [ ] Check systems for CVE-XXXXX
- [ ] Apply patches for CVE-YYYYY
- [ ] Review detection rules for CVE-ZZZZZ

#### 📚 From Readwise Reader (This Week)

**CRITICAL:** Always link to Readwise Reader URLs for interconnection:

**[[Article Title]]** - [Read in Readwise →](https://readwise.io/reader/document/DOCUMENT_ID)
*Author: Name | Added: Oct XX, 2025*
- Key highlight or summary from article
- Relevant CVEs mentioned: CVE-2025-XXXXX

**[[Another Article]]** - [Read in Readwise →](https://readwise.io/reader/document/DOCUMENT_ID)
*Author: Name | Added: Oct XX, 2025*
- Key highlight or summary
- Relevant details

**Note:** Use Readwise Reader links (not original source URLs) to maintain interconnected workflow between Readwise and Obsidian.

#security #vulnerabilities #weekly-update #cve #october2025 #readwise
```

## Step 5: Append to Daily Note

```bash
# Set vault and daily notes paths
VAULT_PATH="$HOME/notes/SecondBrain"
DAILY_NOTES_PATH="$VAULT_PATH/0.Quick Notes 📨/Daily Stuff"
TODAY=$(date +%Y-%m-%d)
DAILY_NOTE="$DAILY_NOTES_PATH/$TODAY.md"

# Verify paths exist
if [ ! -d "$VAULT_PATH" ]; then
    echo "❌ Vault not found at: $VAULT_PATH"
    exit 1
fi

if [ ! -d "$DAILY_NOTES_PATH" ]; then
    echo "❌ Daily notes directory not found at: $DAILY_NOTES_PATH"
    exit 1
fi

# Create note if it doesn't exist
if [ ! -f "$DAILY_NOTE" ]; then
    echo "# $TODAY" > "$DAILY_NOTE"
    echo "" >> "$DAILY_NOTE"
    echo "## Research" >> "$DAILY_NOTE"
    echo "✅ Created new daily note: $TODAY.md"
else
    echo "✅ Found existing daily note: $TODAY.md"
fi

# Append the vulnerability report
echo "" >> "$DAILY_NOTE"
[append formatted content here]
```

## Quality Filters

**ONLY include vulnerabilities that meet ALL criteria:**
1. ✅ Disclosed/published between October 14-20, 2025
2. ✅ Severity: Critical or High
3. ✅ Either: Actively exploited OR Has public PoC OR CISA KEV listed

**EXCLUDE:**
- ❌ Theoretical vulnerabilities
- ❌ Low/Medium severity
- ❌ Anything older than 7 days
- ❌ Duplicate CVEs
- ❌ Vulnerabilities without clear impact

## Error Handling

- If 1Password CLI fails: Stop and report error (never display token in error messages)
- If Readwise has no recent articles: Note this and continue with web research
- If no new vulnerabilities found this week: Report "No critical vulnerabilities this week"
- If vault not found at `~/notes/SecondBrain`: Display error and exit
- If daily notes directory not found: Display error and exit

## Security & Cleanup

```bash
# Clear token from memory after use
unset READWISE_TOKEN

# Verify it's cleared
echo "✅ Session cleaned up securely"
```

**Token Security Checklist:**
- ✅ Token retrieved via 1Password CLI only
- ✅ Token never echoed, printed, or logged
- ✅ Token used only in Authorization headers
- ✅ Token cleared from memory after use
- ✅ No verbose flags that would expose headers

## Success Criteria

Report should answer:
1. What NEW vulnerabilities came out THIS WEEK?
2. Which are actively being exploited RIGHT NOW?
3. What do I need to patch IMMEDIATELY?
4. Where can I find more details?

**Interconnection Requirements:**
- ✅ All Readwise articles link to Readwise Reader URLs (not original sources)
- ✅ Links format: `[Read in Readwise →](https://readwise.io/reader/document/DOCUMENT_ID)`
- ✅ Use `[[Wikilinks]]` for article titles to enable Obsidian graph connections
- ✅ Include #readwise tag for filtering and linking

Keep the report **concise and actionable** - decision-makers should be able to read it in 2-3 minutes and know exactly what to do.
