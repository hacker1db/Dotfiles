---
name: security-intel
description: "Build a CISA/Readwise/web security digest or brief. Triggers: vuln digest, security brief, threat intel, check CISA KEV, weekly security review."
---

# Security Intelligence

Fetch security intelligence and output as a digest (quick, default) or brief (comprehensive).

## Readwise Access

Follow `../readwise-cli/references/access-patterns.md`.

## Modes

- **Digest** (default / `--digest`): appended to today's Obsidian daily note; covers last 7 days
- **Brief** (`--brief` / `--days=N`): standalone file in vault; N = 1, 7, or 30 days

## Workflow (8 Steps)

1. **Access Readwise** through the plugin on OpenAI models; otherwise get the token from 1Password: `op item get 37nc3retjhuxh6qafon4b65i6q --reveal --fields apikey`
2. **Compute date cutoff** from `--days` (default 7)
3. **Fetch CISA KEV** — `https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json`; filter by `dateAdded >= cutoff`
4. **Fetch Readwise articles** — plugin `_reader_list_documents` on OpenAI models; fallback API `/api/v3/list/?location=new&category=article`; categorize into Threat Intel / AppSec / Cloud Security buckets
5. **Search Readwise highlights** — plugin `_readwise_search_highlights` on OpenAI models; fallback Grep over Readwise vault files for themes from KEV results; surface relevant prior reading
6. **Web search gap-fill** — targeted search for zero-days not in CISA (max 3 findings)
7. **Build output** — digest or brief format (see `references/output-templates.md`)
8. **Cleanup** — `unset READWISE_TOKEN`

**Token security**: never display, echo, log, or show the Readwise token in output.

See `references/output-templates.md` for the full digest and brief output formats.
