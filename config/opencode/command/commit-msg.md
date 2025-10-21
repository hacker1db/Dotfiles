---
description: Generate conventional commit message
agent: commit-msg
---
Analyze staged changes (files, additions, deletions, scope hints from paths, branch name via !`git rev-parse --abbrev-ref HEAD`).
Infer type (feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert) and scope.
Return the with body variant: subject + detailed body (what & why, not how, with bullet points for key changes) + issue refs (if pattern #\d in branch or diff).
Subject: imperative, lowercase, no trailing period, <=50 chars.
Body: wrap ~72 chars, include breaking change note if detected.
