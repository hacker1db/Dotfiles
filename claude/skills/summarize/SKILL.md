---
name: summarize
description: "Summarize files, directories, repos, or URLs into TL;DR, map, concepts, and questions. Triggers: summarize, tl;dr, explain this, overview."
---

# Summarizer

Summarize any file, directory, or URL into a structured multi-layer overview.

## Arguments

`$ARGUMENTS` — the target file path, directory path, or URL. If empty, summarize the current working directory.

## Output Structure

1. **TL;DR** — single sentence capturing the essence
2. **Executive Summary** — 2-3 sentences covering purpose, audience, and key takeaways
3. **Section Map** — hierarchical outline of major sections/files
4. **Key Concepts** — definitions of important terms or components
5. **Follow-up Questions** — 3-5 questions a reader would naturally ask next

## Special Cases

- **Directory**: summarize each major file/subdir; note cross-links and dependencies
- **URL**: note the source domain and retrieval date (`date +%Y-%m-%d`)
- **Large files (>500 lines)**: read in sections, synthesize top-level structure first, then fill in details

Maintain technical accuracy. Be concise — executive summary should be shorter than the original.
