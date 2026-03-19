---
description: Safe incremental refactor proposals with diff snippets, test impact analysis, and rollback plan. Use this skill when the user wants to clean up code, reduce duplication, simplify logic, extract functions, improve naming, or restructure without changing behavior. Triggers on "refactor this", "clean up", "simplify", "extract function", "reduce duplication", "improve this code".
---
Read the target file(s) referenced in $ARGUMENTS before proposing anything. Understand the current structure first.

Given the refactoring goal: $ARGUMENTS

Identify current pain points (duplication, complexity, mixed responsibilities, poor naming) and propose a minimal safe sequence of changes.

Output:
1. **Current pain** — what's wrong and why it matters (1-2 sentences)
2. **Stepwise plan** — each step atomic and independently safe to commit
3. **Diff snippets** (` ```diff `) for key changes only — not exhaustive
4. **Test impact** — files to add or update; flag if behavior-observable tests exist
5. **Risk notes + rollback** — what could break, how to revert each step

Preserve semantics. Prefer extraction over rewrite. Avoid speculative changes beyond the stated goal. End with a checklist of steps.
