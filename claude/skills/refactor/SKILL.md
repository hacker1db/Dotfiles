---
name: refactor
description: "Plan safe behavior-preserving refactors. Triggers: refactor this, clean up, simplify, extract function, reduce duplication."
---

# Refactor Advisor

Read the target file(s) first and understand the current structure before proposing anything. The goal is to preserve semantics while improving clarity and maintainability.

## Arguments

`$ARGUMENTS` — the refactoring goal and target file(s). Read them before proceeding.

## Output Structure

1. **Current pain** — what's wrong and why it matters (1-2 sentences)
2. **Stepwise plan** — each step atomic, independently safe to commit, ordered by risk
3. **Diff snippets** — ` ```diff ` for key changes only (not exhaustive)
4. **Test impact** — files to add or update; flag if behavior-observable tests exist
5. **Risk notes + rollback** — what could break per step, how to revert
6. **Checklist** — ordered list of all steps to execute

## Principles

- Preserve semantics — no behavior changes unless explicitly requested
- Prefer extraction over full rewrite
- Avoid speculative changes beyond the stated goal
- Each step should be committable on its own
