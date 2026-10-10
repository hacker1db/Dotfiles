---
name: md-convert
description: "Convert specified Markdown files to HTML, PDF, or Word DOCX, including an explicit export of a saved plan or note. Use for md2pdf, md2html, md2docx, or a Markdown file conversion request. General writing, planning, document analysis, or conversion of non-Markdown input is outside this workflow."
argument-hint: <file.md|glob> [--to html|pdf|docx] [--out <path>] [--stylesheet <css>]
---

# md-convert

Convert one or more Markdown files to HTML, PDF, or Word (docx).

Plan Manager is the canonical durable record for user-facing, implementation,
project, investigation, PR, and team plans. Do not create conversion artifacts
automatically while planning. When the user explicitly invokes `md-convert` or
asks to export or render a plan, convert the requested canonical plan to the
requested format, including HTML.

## Arguments

Resolve inputs from the user request or `$ARGUMENTS`:
- `<file.md>` or glob (e.g. `docs/runbooks/*.md`) — source(s) to convert; ask if not provided
- `--to html|pdf|docx` — output format; ask if not provided (accept `word` as alias for `docx`)
- `--out <path>` — output file or directory; defaults to same directory as source with matching stem
- `--stylesheet <css>` — PDF only; defaults to `~/.dotfiles/claude/md-to-pdf.css`

## Format Behavior

### HTML (`--to html`)
Read each source file fully, then write one self-contained `.html` file per source.
- Embed a clean **dark-mode** stylesheet inline (`<style>`) — no external dependencies. Always render dark, regardless of the OS/browser color-scheme preference (do not rely on `prefers-color-scheme`).
  - Use a dark background (e.g. `#0d1117`), light body text (e.g. `#e6edf3`), a muted secondary color for de-emphasized text, and a slightly lighter panel background (e.g. `#161b22`) for code blocks, tables, and cards.
  - Ensure sufficient contrast (WCAG AA) and pick a readable accent color for links (e.g. `#58a6ff`).
  - Set `color-scheme: dark` on `:root` so form controls and scrollbars match.
- Preserve headings, code blocks, tables, fenced diagrams, and relative links.
- Output: `<stem>.html` next to the source unless `--out` overrides.
- Offer or use a supported in-app preview when useful, or open a browser only when requested. Discover the available preview capability; do not assume macOS or run `open` unconditionally.

### PDF (`--to pdf`)
Check whether `md-to-pdf` and the requested stylesheet exist before invoking them. If unavailable, use an installed supported Markdown or HTML to PDF converter with comparable output, or report the missing dependency. Do not install software automatically. Preferred CLI:
```
md-to-pdf <file> --stylesheet <css>
```
- Default stylesheet: `~/.dotfiles/claude/md-to-pdf.css`
- Custom stylesheet: use `--stylesheet` argument.
- Resolve glob input to explicit files and pass each path as a safely quoted argument, one file per conversion. Do not execute user text as shell syntax.
- Honor `--out`. When the CLI writes next to the source, move only the newly generated PDF to the requested destination after success. Detect existing outputs before conversion so they are not silently overwritten.

### DOCX (`--to docx` or `--to word`)
Check for an available pandoc installation or supported document conversion capability. Preferred CLI:
```
pandoc <file> -o <stem>.docx
```
- Glob input: run pandoc once per matched file.
- Output: `<stem>.docx` next to the source unless `--out` overrides.

## Execution Rules

1. Resolve the glob with an available file search capability to a concrete list. Validate sources, output paths, and converter availability. Quote paths safely, including spaces and shell metacharacters. Preserve source files. Respect requested overwrite behavior; ask before replacing an existing output when intent is unclear.
2. For each file, confirm the planned output path in a pre-run summary if converting more than one file.
3. Run conversions and verify outputs exist and are readable in the requested format. For PDF and DOCX, use available inspection or rendering tools to check representative layout. Stop and report failures with the successful and failed files identified. A missing stylesheet requires an explicit fallback disclosure, not a false claim that it was applied.
4. After all conversions, print a result table:

   | Source | Output | Status |
   |--------|--------|--------|
   | docs/runbook.md | docs/runbook.pdf | ✓ |
