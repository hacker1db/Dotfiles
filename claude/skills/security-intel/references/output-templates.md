# Security Intel — Output Templates

## Daily Note Path

```bash
VAULT="$HOME/notes/SecondBrain"
DAILY_NOTE="$VAULT/0.Quick Notes 📨/Daily Stuff/$TODAY.md"
[ ! -f "$DAILY_NOTE" ] && printf "# %s\n\n" "$TODAY" > "$DAILY_NOTE"
```

Check for duplicate before appending:
```bash
grep -q "Security Intel — $TODAY" "$DAILY_NOTE" && echo "⚠️ Already appended today — skipping" && unset READWISE_TOKEN && exit 0
```

Append with `printf '%s\n' "$DIGEST_CONTENT" >> "$DAILY_NOTE"` (not heredoc — `$HOME` won't expand inside quoted heredoc delimiters).

---

## DIGEST MODE Template

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

*(Omit category section if no articles match it)*

#### 💡 Related From Your Reading

- **[article/book title]** — [author]
  > [relevant highlight]
  *Your note:* [personal [n] annotation if present]

#### 🌐 Additional Findings

- **[CVE or finding]** — [brief description] — [source URL]

#### 🎯 Immediate Actions

*(Top 2-3 concrete actions: patch X, review Y, monitor Z)*

#security #cve #security-intel
```

---

## BRIEF MODE Template

Write to: `$HOME/notes/SecondBrain/0.Quick Notes 📨/Security Intel Brief - [TODAY].md`

```markdown
## 🔒 Security Intelligence Brief — {Daily|Weekly|Monthly}

> Generated: [timestamp] | Coverage: past [N] day(s)

### 🚨 Critical CVEs

**[CVE-ID]** — [vendor/product] — Added [dateAdded] [🔴 Ransomware if applicable]
- [shortDescription]
- **Action:** [requiredAction] by [dueDate]

### 📊 Vulnerability Themes

*(Group CVEs by vendor/type, counts, ransomware involvement)*

### 📝 Personal Security Notes (Updated This Period)

- [note name] — modified [date]

### 📚 Readwise Security Highlights

**Tier 1 — Direct Threats:** [title] — [source] — [added date] | [relevance sentence]
**Tier 2 — Adjacent Topics:** …
**Tier 3 — Trusted Sources:** …

### 🎯 Trend Analysis

- Most targeted vendor this period: [vendor]
- Reading focus themes: [top 3 from Readwise]
- Work notes focus: [top topics from vault]

### ✅ Recommended Actions

**Immediate (Today):** [patch tasks]
**This Week:** [monitoring/review tasks]
**This Month:** [strategic items]

### 📅 Next Brief

[Suggest next run date based on --days value]

#security #intelligence #cve #threat-analysis #{daily|weekly|monthly}
```

---

## Readwise Article Categorization Keywords

| Bucket | Keywords |
|--------|---------|
| 🔴 Threat Intel | CVE, exploit, breach, attack, malware, ransomware, zero-day, patch, vulnerability, RCE, injection, XSS, phishing, backdoor |
| 🔵 AppSec | OWASP, authentication, auth bypass, API security, pentest, web hacking, bug bounty, security testing, Caido, Burp, supply chain |
| ☁️ Cloud Security | AWS, Azure, GCP, IAM, S3, bucket, container, kubernetes, k8s, privilege escalation, cloud misconfiguration, Terraform, infrastructure |
