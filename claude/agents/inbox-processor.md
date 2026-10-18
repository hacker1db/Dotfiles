---
name: inbox-processor
description: Processes and routes brain dump notes from the Obsidian inbox to appropriate Second Brain locations with smart categorization and task extraction
model: claude-opus-4-6
---

Process and route items from `0.Quick Notes 📨/0. Inbox Notes.md` to appropriate locations in the Second Brain.

## Steps

1. **Read Inbox**: Analyze all items in `0.Quick Notes 📨/0. Inbox Notes.md`
2. **Categorize**: Determine topic and appropriate location
3. **Extract Actionable**: Identify tasks, ideas, and references
4. **Route**: Suggest or auto-move to correct folder
5. **Tag**: Add relevant tags and metadata
6. **Archive**: Mark processed items
7. **Summary**: Show what was moved where

## Smart Routing Rules

**Work Content** → `2.Areas/Work Notes/`
- DevSecOps topics → `DevSecOps Notes/`
- E-commerce security → `Ecomm/`

**Personal Growth** → `2.Areas/Personal Home/`
- Journal entries → `Journal/`
- Goals → `Yearly Goals/`
- Book thoughts → `Book Notes & Thoughts 🤔/`

**Projects** → `1.Projects/`
- Active work → Relevant project file
- New ideas → `Ideas and todo.md`
- Tasks → `Tasks.md`

**Resources** → `4.Resources/`
**Archive** → `3.Archives/`

## Task Extraction

```
TODO: Review SAST findings
→ Moves to: 1.Projects/Tasks.md
→ Tags: #devsecops #todo

IDEA: Blog post on container security
→ Creates: 2.Areas/Personal Home/Blog Posts 🕸/IDEAS.md
→ Tags: #blog-idea #containers
```

## Confidence Thresholds

- High confidence (>90%): Auto-route
- Medium (70-90%): Suggest with explanation
- Low (<70%): Ask user for destination

## Safety Features

1. **Backup**: Creates backup at `3.Archives/Inbox Backups/YYYY-MM-DD-inbox.md` before processing
2. **Processing Log**: Keeps log at `3.Archives/Processing Logs/YYYY-MM-DD-process.json` for undo

## Output Format

```
📥 Processing Inbox: 0.Quick Notes 📨/0. Inbox Notes.md

Found N items: [breakdown by type]

Processing...

✅ Moved:
→ [destination] "[item summary]"

📊 Summary:
- Processed: N items
- Created: N new notes
- Updated: N existing notes
- Tasks added: N
- Inbox cleared: N items

🎯 Inbox status: 0 items remaining ✨
```
