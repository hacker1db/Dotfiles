---
name: md-convert
description: "Convert Markdown files to HTML, PDF, or Word (docx). Triggers: md2pdf, md2html, md2docx, convert to pdf, convert to word, export markdown, render markdown, plan to HTML, notes to HTML."
argument-hint: <file.md|glob> [--to html|pdf|docx] [--out <path>] [--stylesheet <css>]
allowed-tools: [Read, Write, Glob, Bash]
---

# md-convert

Convert one or more Markdown files to HTML, PDF, or Word (docx).

## Arguments

Parse `$ARGUMENTS`:
- `<file.md>` or glob (e.g. `docs/runbooks/*.md`) — source(s) to convert; ask if not provided
- `--to html|pdf|docx` — output format; ask if not provided (accept `word` as alias for `docx`)
- `--out <path>` — output file or directory; defaults to same directory as source with matching stem
- `--stylesheet <css>` — PDF only; defaults to `~/.dotfiles/claude/md-to-pdf.css`

## Format Behavior

### HTML (`--to html`)
Read each source file fully, then write one self-contained `.html` file per source.
- Embed a clean light stylesheet inline (`<style>`) — no external dependencies.
- Preserve headings, code blocks, tables, fenced diagrams, and relative links.
- Output: `<stem>.html` next to the source unless `--out` overrides.

### PDF (`--to pdf`)
Run `md-to-pdf` via CLI:
```
md-to-pdf <file> --stylesheet <css>
```
- Default stylesheet: `~/.dotfiles/claude/md-to-pdf.css`
- Custom stylesheet: use `--stylesheet` argument.
- Glob input: shell expands to multiple files; pass all to one `md-to-pdf` invocation.
- Output: `<stem>.pdf` next to each source (md-to-pdf default behavior).

### DOCX (`--to docx` or `--to word`)
Run pandoc:
```
pandoc <file> -o <stem>.docx
```
- Glob input: run pandoc once per matched file.
- Output: `<stem>.docx` next to the source unless `--out` overrides.

## Execution Rules

1. Resolve the glob (via Glob tool or shell) to a concrete file list before converting.
2. For each file, confirm the planned output path in a pre-run summary if converting more than one file.
3. Run conversions; stop and display the error if any command exits non-zero.
4. After all conversions, print a result table:

   | Source | Output | Status |
   |--------|--------|--------|
   | docs/runbook.md | docs/runbook.pdf | ✓ |
