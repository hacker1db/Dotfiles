---
name: md2html
description: "Convert Markdown into a self-contained HTML page. Triggers: md2html, render markdown, plan to HTML, notes to HTML."
argument-hint: <file.md> [--out output.html]
allowed-tools: [Read, Write, Glob, Bash]
---

# md2html

Convert the source Markdown into one self-contained HTML file.

If no file is given, ask which `.md` file to convert.

Read the source fully, preserve headings, code blocks, tables, links, and diagrams, and write the HTML next to the source unless `--out` is provided.
