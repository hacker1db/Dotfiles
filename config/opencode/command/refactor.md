---
description: Safe incremental refactor proposals
agent: refactor
---
Given the refactoring goal: $ARGUMENTS
Identify current pain (duplication, complexity, responsibility mixing) and propose a minimal safe sequence of changes.
Output:
1. Rationale (1-2 sentences)
2. Stepwise plan (each step atomic)
3. Diff snippets (```diff) only for key changes
4. Test impact summary (files to add/update)
5. Risk notes + rollback plan
Preserve semantics; avoid speculative rewrites. Prefer extraction over rewrite. End with checklist.
