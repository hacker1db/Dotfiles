---
name: security-intel
description: "Create a current security intelligence digest or brief from CISA KEV, Readwise, and web sources, including weekly security reading reviews. Use for threat briefings, not code or architecture reviews."
---

# Security Intelligence

Produce a sourced security digest or brief. Read `references/output-templates.md` for the required content and vault destinations.

1. Resolve the user's timezone and requested window. Default to seven days. Digest mode appends to today's daily note; brief mode creates a standalone note. `--digest`, `--brief`, and `--days=N` are request conventions, not tool flags.
2. Follow `../readwise-cli/references/access-patterns.md`. Use authenticated capabilities on any model. Do not reveal credentials or request raw tokens.
3. Fetch the CISA KEV feed at `https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json` and filter `dateAdded` by the cutoff.
4. Retrieve relevant Reader articles and Readwise highlights. Use verified schemas, paginate, and label the date field used. Vault highlights can supply prior context when online access is unavailable.
5. Fill evidence gaps with up to three web findings from authoritative sources. Distinguish confirmed exploitation from other vulnerability reports.
6. Write the requested artifact, preserve daily note structure, and check duplicate entries. Cite sources, disclose unavailable feeds and partial coverage, and report its path. Never interpret retrieval failure as zero findings.
