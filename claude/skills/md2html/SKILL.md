---
name: md2html
description: Convert long-form Markdown into a single self-contained HTML page. Use when the user asks for /md2html, wants a .md file turned into .html, or asks to render a plan, spec, RFC, runbook, postmortem, brainstorm, or notes document as HTML.
argument-hint: <file.md> [--out output.html]
allowed-tools: [Read, Write, Glob, Bash]
---

# md2html

Convert the source Markdown into one self-contained HTML file.

If no file is given, ask which `.md` file to convert.

Read the source fully, preserve headings, code blocks, tables, links, and diagrams, and write the HTML next to the source unless `--out` is provided.
