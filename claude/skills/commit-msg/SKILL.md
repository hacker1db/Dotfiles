---
name: commit-msg
description: "Generate a conventional commit message by analyzing staged changes. Use this skill when the user wants to write a commit message, format a commit, create a git commit, or needs help naming a commit. Triggers on 'write a commit message', 'generate commit', 'commit message for my changes', 'what should I name this commit', 'help me commit'."
---

# Commit Message Generator

Analyze staged changes and produce a conventional commit message with inferred type, scope, and a descriptive body.

## Output Format

```
<type>(<scope>): <subject>        ← max 50 chars
                                  ← blank line
<body>                            ← wrap at 72 chars; explain what AND why
                                  ← blank line
<footer>                          ← issue refs: Closes #123, Refs #456
```

## Conventional Types

`feat` · `fix` · `refactor` · `docs` · `test` · `build` · `ci` · `chore` · `perf` · `style`

## Rules

- Subject: imperative mood, no period, ≤50 chars
- Scope: infer from changed directory or module (optional but helpful)
- Body: explain *what* changed and *why* — not how; wrap at 72 chars
- Footer: include issue refs if detectable from branch name or file comments
- Breaking changes: add `BREAKING CHANGE:` in footer

## Steps

1. Run `git diff --cached` to read staged changes
2. Identify the dominant change type and affected scope
3. Write subject line ≤50 chars in imperative mood
4. Write body summarizing what and why (skip if change is self-evident)
5. Add footer with issue refs if detectable
