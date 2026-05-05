---
name: security-intel
description: "Pull security intelligence from CISA KEV, Readwise, and the web, then output as a quick digest or full brief. Use when you want to catch up on new CVEs, check actively exploited vulnerabilities, run a daily security update, generate a weekly threat report, or get a security intelligence brief. Triggers on 'vuln digest', 'security brief', 'what CVEs came out this week', 'threat intel', 'check CISA KEV', 'security update', 'weekly security review', 'security intel'."
---

# Security Intelligence

Fetch security intelligence and output as a digest (quick, default) or brief (comprehensive).

## Readwise Plugin

When running on an OpenAI model with the Readwise plugin available, use it for all Readwise/Reader work instead of fetching a token or calling the Readwise HTTP API:
- `_reader_list_documents` for recent Reader articles, filtered by `location=new`, `category=article`, and `updated_after` when useful
- `_reader_search_documents` for security-themed Reader content
- `_readwise_search_highlights` for prior saved highlights related to CISA themes
- `_reader_get_document_details` and `_reader_get_document_highlights` when a document needs more context

Only use the token/API workflow below when plugin tools are unavailable.

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
