---
name: obsidian-vault
description: "Use as supporting guidance when creating, editing, organizing, inspecting backlinks, or linking Obsidian vault notes and indexes."
---

# Obsidian Vault

## Vault location

`~/notes/SecondBrain/`

Read the vault instructions and nearby notes to determine the destination. This vault uses numbered folders as well as root notes; preserve its existing organization.

## Naming conventions

- **Index notes**: aggregate related topics (e.g., `Ralph Wiggum Index.md`, `Skills Index.md`, `RAG Index.md`)
- **Title Case** for all note names
- Use the existing destination for the note type and wikilinks for connections. Follow a specialized writing skill for its content contract and use this skill for vault conventions.

## Linking

- Use Obsidian `[[wikilinks]]` syntax: `[[Note Title]]`
- Notes link to dependencies/related notes at the bottom
- Index notes are just lists of `[[wikilinks]]`

## Workflows

### Search for notes

Use the available file search tools on the vault path. Prefer `rg --files` for filenames and `rg` for text when installed:

```bash
# Search by filename
rg --files ~/notes/SecondBrain/ -g "*.md" | rg -i "keyword"

# Search by content
rg -l "keyword" ~/notes/SecondBrain/ -g "*.md"
```

### Create a new note

1. Use **Title Case** for filename
2. Write content as a unit of learning
3. Add `[[wikilinks]]` to related notes at the bottom
4. If part of a numbered sequence, use hierarchical numbering

### Find backlinks

Search for all notes that reference a given note:

```bash
grep -rl "\[\[Note Title\]\]" ~/notes/SecondBrain/
```

### Find index notes

```bash
find ~/notes/SecondBrain/ -name "*Index*"
```
