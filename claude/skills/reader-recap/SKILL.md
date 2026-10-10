---
name: reader-recap
description: "Summarize recent Reader moves and annotations over a requested time window, with a conversational recap and suggested follow ups. Use for reading activity recaps, not inbox triage or RSS catchup."
---

# Reader Recap

Read `references/briefing.md` and `../readwise-cli/references/access-patterns.md` for access. This workflow only reads data.

1. Resolve the requested window, defaulting to the last 24 hours in the user's timezone. Read `reader_persona.md` if available.
2. Fetch and paginate archived and later documents using supported schemas. Request IDs, titles, authors, source links, notes, `last_moved_at`, `updated_at`, and reading progress. Filter returned `last_moved_at` locally by the cutoff. An update cannot establish movement or completion; if move dates are unavailable, label results as recently updated documents and disclose the limitation. Never invent a movement filter flag.
3. Deduplicate by ID and fetch highlights. Filter highlights by their own timestamps. Otherwise identify lifetime highlights as context, without claiming they were created during this window. Absence of highlights does not mean unread; archive does not mean finished.
4. Write concise paragraphs emphasizing annotations, then highlighted items and numbered follow ups. Include links and distinguish observed activity from suggested actions. Report empty results only with verified coverage; disclose limits.
