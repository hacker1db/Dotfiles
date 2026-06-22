---
description: Pull CISA, Readwise, vault, and web security intelligence into a digest or brief.
---

# Security Intel

Use the `security-intel` skill with `$ARGUMENTS`.

Preserve the skill workflow:
- Default to digest mode; use brief mode for `--brief` or `--days=N`.
- Follow the shared Readwise access guidance and never display or log tokens.
- Pull CISA KEV directly, then enrich with Readwise/Reader, vault highlights, and targeted web research.
- Append the digest to today's daily note or write the standalone brief as instructed by the skill.
- Unset any token or sensitive environment variable before finishing.
