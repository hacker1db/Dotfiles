---
name: readwise-cli
description: "Look up exact Readwise CLI commands, flags, authentication, or CLI fallbacks for Reader documents and highlights. Use when a workflow selects the CLI or the user asks for terminal commands."
---

# Readwise CLI

Read `references/access-patterns.md` first to select an available access method. Read `references/commands.md` only for the needed operation. Reader stores documents; Readwise stores highlights and daily reviews.

Use `readwise --help` and the specific command's `--help` to verify current options. `--json` returns machine readable output; `--refresh` refreshes tool metadata. If command discovery fails, report that limitation instead of inventing options.

Prefer an existing authenticated session. For missing authentication, use `readwise login`, the interactive OAuth flow. Never ask for a token in chat or place one in a command argument, output, or file. If login requires user interaction, state the exact action needed. If the CLI is absent, report the missing dependency and use another available route; install only within the user's authorized setup scope.

Return the requested result with source IDs or links, coverage, and confirmed mutation outcomes. Paginate before claiming completeness; preserve existing tags and notes when updating.
