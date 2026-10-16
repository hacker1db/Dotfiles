# MD-to-SVX — Conversion Guide

## Frontmatter Mapping

| Obsidian field | SVX field | Notes |
|---|---|---|
| `title` | `title` | Keep, wrap in quotes |
| `date` | `date` | ISO format `YYYY-MM-DD`, no quotes |
| `author` | `author` | Always `hacker1db` (no quotes) |
| `description` | `subtitle` | Use description as subtitle |
| `tags` | `tags` | YAML list: one item per line with `  - "tag"` |
| `categories` | `series` | Map to series array; `[]` if no clear series |
| `draft` | `draft` | Keep as-is |
| — | `thumbnail` | Unsplash search → `https://images.unsplash.com/photo-{id}?w=1200` |
| — | `youtube` | Add `youtube: ""` (empty) |
| — | `toc` | Add `toc: true` by default |

**Remove Obsidian-only fields**: `aliases`, `cssclass`, `cssclasses`, `publish`, `featured`, `permalink`, `uid`.

After closing `---`, add `<!-- Photo by [Name] on Unsplash -->`.

## Syntax Conversion

### Wikilinks
- `[[Page Name]]` → `Page Name`
- `[[Page Name|Display Text]]` → `Display Text`
- `[[Page Name#Heading]]` → `Page Name > Heading`

### Embeds
- `![[embedded-note]]` → remove (warn user)
- `![[image.png]]` → `![image](/images/posts/image.png)` (remind user to copy file)

### Callouts
- `> [!note] Title` → `> **Note:** Title`
- `> [!warning] Title` → `> **Warning:** Title`
- `> [!tip] Title` → `> **Tip:** Title`

### Remove
- `%%comment%%` blocks
- `dataview` and `templater` code blocks / inline queries

### Preserve
- `<!-- Research Sources: ... -->` HTML comments

## Category Directory Mapping

| Topic | Directory |
|-------|-----------|
| Security / CyberSecurity / InfoSec / DevSecOps | `CyberSecurity/` |
| DevOps / Infrastructure / Docker / Kubernetes | `DevOps/` |
| Programming / Development / Code | `Programing/` (existing spelling) |
| Testing / QA | `Testing/` |

## Slug Generation

Lowercase title → replace spaces and special chars with hyphens → remove consecutive hyphens → strip leading/trailing hyphens.

Example: `"Security for Developers: Essential Knowledge"` → `security-for-developers-essential-knowledge.svx`

## Batch Mode

Iterate over vault blog directory. Skip: files with no frontmatter, files already present in output directory (warn + ask). Show summary table: filename, category, status.
