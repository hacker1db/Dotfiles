---
name: readwise-mcp
description: "Look up Readwise or Reader MCP tool arguments, connection setup, and connector operations when an active workflow selects MCP. Use for tool schema questions, not CLI syntax."
---

# Readwise MCP

Read `../readwise-cli/references/access-patterns.md` for the shared access router. Select by capability and authentication. Discover the actual tools exposed by the current host, then read `references/tools.md` for the needed operation. Tool prefixes and supported fields vary; use the live schema before examples.

Reader stores saved documents; Readwise stores highlights and daily reviews. Save source URLs to Reader unless the user requests Highlights. Paginate and request only needed fields. Preserve current tags and notes during updates. Report result IDs or links, coverage, and confirmed mutation outcomes.

An unconfigured connection is a setup issue. When setup is requested, the Readwise HTTP MCP endpoint is `https://mcp2.readwise.io/mcp`; authentication uses OAuth. Follow the host's connection flow. Never request a raw token in chat or rewrite client configuration merely to answer a reading request.
