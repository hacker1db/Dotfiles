---
name: obsidian-vault
description: Search, create, and manage notes in the Obsidian vault with wikilinks and index notes. Use when the user wants to find, create, update, or organize notes in Obsidian, search for topics in their second brain, create new atomic notes, build index notes, or link related concepts together.
---

# Obsidian Vault

## Vault location

`~/notes/SecondBrian/`

Mostly flat at root level — no folder hierarchy for organization.

## Naming conventions

- **Index notes**: aggregate related topics (e.g., `Ralph Wiggum Index.md`, `Skills Index.md`, `RAG Index.md`)
- **Title Case** for all note names
- No folders for organization — use links and index notes instead

## Linking

- Use Obsidian `[[wikilinks]]` syntax: `[[Note Title]]`
- Notes link to dependencies/related notes at the bottom
- Index notes are just lists of `[[wikilinks]]`

## Workflows

### Search for notes

Use Glob/Grep tools directly on the vault path:

```bash
# Search by filename
find ~/notes/SecondBrian/ -name "*.md" | grep -i "keyword"

# Search by content
grep -rl "keyword" ~/notes/SecondBrian/ --include="*.md"
```

### Create a new note

1. Use **Title Case** for filename
2. Write content as a unit of learning
3. Add `[[wikilinks]]` to related notes at the bottom
4. If part of a numbered sequence, use hierarchical numbering

### Find backlinks

Search for all notes that reference a given note:

```bash
grep -rl "\[\[Note Title\]\]" ~/notes/SecondBrian/
```

### Find index notes

```bash
find ~/notes/SecondBrian/ -name "*Index*"
```
