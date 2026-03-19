---
description: Multi-layer documentation summary with TL;DR, section map, key concepts, and follow-up questions. Use this skill when the user wants to summarize a file, understand a document quickly, get a TL;DR, summarize a directory of files, or summarize content from a URL. Triggers on "summarize", "tl;dr", "explain this file", "give me an overview", "what does this do", "summarize this repo".
---
Summarize target input (file, directory, or URL): $ARGUMENTS

If $ARGUMENTS is empty, summarize the current working directory.

Provide:
1. **TL;DR** (single sentence)
2. **Executive Summary** (2-3 sentences covering purpose, audience, and key takeaways)
3. **Section Map** (hierarchical outline of major sections/files)
4. **Key Concepts** (definitions of important terms or components)
5. **Follow-up Questions** (3-5 questions a reader would naturally ask next)

Notes:
- For a **directory**: summarize each major file/subdir and note cross-links or dependencies
- For a **URL**: note the source domain and retrieval date via `date +%Y-%m-%d`
- For **large files** (>500 lines): read in sections, synthesize top-level structure first
- Maintain technical accuracy; be concise
