# Inbox Processor

Automated processing and routing of brain dump notes from your inbox.

## Command

### /inbox-process

Process and route items from `0.Quick Notes 📨/0. Inbox Notes.md` to appropriate locations in your Second Brain.

**What it does:**
1. **Read Inbox**: Analyzes all items in inbox note
2. **Categorize**: Uses AI to determine topic and appropriate location
3. **Extract Actionable**: Identifies tasks, ideas, and references
4. **Route**: Suggests or auto-moves to correct folder
5. **Tag**: Adds relevant tags and metadata
6. **Archive**: Marks processed items
7. **Summary**: Shows what was moved where

## Usage

```
/inbox-process
```

Run weekly (Friday) or when inbox has 10+ items.

## How It Works

### 1. Inbox Analysis

Reads `0.Quick Notes 📨/0. Inbox Notes.md` and identifies:
- **Quick Captures**: Random thoughts, ideas
- **Links**: Articles, resources to save
- **Tasks**: Action items to track
- **Meeting Notes**: Context to preserve
- **Code Snippets**: Examples to file
- **Learning**: Concepts to expand

### 2. Smart Routing

Routes based on content:

**Work Content** → `2.Areas/Work Notes/`
- DevSecOps topics → `DevSecOps Notes/`
- E-commerce security → `Ecomm/`
- General security → Create appropriate subfolder

**Personal Growth** → `2.Areas/Personal Home/`
- Journal entries → `Journal/`
- Goals → `Yearly Goals/`
- Travel ideas → `Travel Plans/`
- Book thoughts → `Book Notes & Thoughts 🤔/`

**Projects** → `1.Projects/`
- Active work → Relevant project file
- New ideas → `Ideas and todo.md`
- Tasks → `Tasks.md`

**Resources** → `4.Resources/`
- Reference material
- External links
- Templates

**Archive** → `3.Archives/`
- Completed items
- No longer relevant

### 3. Task Extraction

Automatically identifies and extracts:
```
TODO: Review SAST findings
→ Moves to: 1.Projects/Tasks.md
→ Tags: #devsecops #todo

IDEA: Blog post on container security
→ Creates: 2.Areas/Personal Home/Blog Posts 🕸/IDEAS.md
→ Tags: #blog-idea #containers
```

## Output Format

**Console Output:**
```
📥 Processing Inbox: 0.Quick Notes 📨/0. Inbox Notes.md

Found 12 items:
- 5 work notes
- 3 personal reflections
- 2 blog ideas
- 1 task
- 1 resource link

Processing...

✅ Moved:
→ 2.Areas/Work Notes/DevSecOps Notes/SAST Integration.md
   "Review SAST tool options for Python"

→ 2.Areas/Personal Home/Journal/2025-01-17.md
   "Reflection on work-life balance"

→ 2.Areas/Personal Home/Blog Posts 🕸/IDEAS.md
   "Container security hardening guide"
   "API authentication patterns"

→ 1.Projects/Tasks.md
   "[ ] Review quarterly OKRs by Friday"

→ 4.Resources/Readwise/Saved Articles.md
   "https://... - DevSecOps maturity models"

📊 Summary:
- Processed: 12 items
- Created: 2 new notes
- Updated: 3 existing notes
- Tasks added: 1
- Inbox cleared: 12 items

🎯 Inbox status: 0 items remaining ✨
```

**Updated Inbox Note:**
```markdown
# 0. Inbox Notes

*Last processed: 2025-01-17 via /inbox-process*

<!-- Processed items moved below -->

---

## Processed Archive (Auto-generated)

### 2025-01-17
- [x] Review SAST tool options → Moved to DevSecOps Notes
- [x] Reflection on balance → Moved to Journal
- [x] Blog ideas (2) → Moved to Blog IDEAS
- [x] OKR review task → Moved to Tasks
- [x] Article link → Saved to Resources

---

## New Captures (Add below)

[Empty - ready for new captures]
```

## Processing Rules

### Work Notes
**Triggers:** DevSecOps, security, CI/CD, pipeline, SAST, DAST, containers, kubernetes, cloud
**Destination:** `2.Areas/Work Notes/DevSecOps Notes/[Topic].md`
**Tags:** #devsecops, #security, #work

### Blog Ideas
**Triggers:** "blog idea", "post about", "write about"
**Destination:** `2.Areas/Personal Home/Blog Posts 🕸/IDEAS.md`
**Tags:** #blog-idea

### Journal Entries
**Triggers:** "reflection", "feeling", "thought about", dates
**Destination:** `2.Areas/Personal Home/Journal/YYYY-MM-DD.md`
**Tags:** #journal, #personal

### Tasks
**Triggers:** "TODO", "task", "need to", "remember to"
**Destination:** `1.Projects/Tasks.md`
**Format:** `- [ ] [Task] #due/YYYY-MM-DD`

### Resources
**Triggers:** URLs, "read", "article", "video"
**Destination:** `4.Resources/[Category]/`
**Tags:** Based on content

## Advanced Options

### Dry Run (Preview Only)
```
/inbox-process --dry-run
```
Shows what would be moved without actually moving.

### Interactive Mode
```
/inbox-process --interactive
```
Asks for confirmation on each item.

### Auto Mode (Default)
```
/inbox-process
```
Automatically routes with high confidence; asks for ambiguous items.

### By Date Range
```
/inbox-process --since=2025-01-01
```
Only process items added after date.

## Safety Features

1. **Backup**: Creates backup of inbox before processing
   - Location: `3.Archives/Inbox Backups/YYYY-MM-DD-inbox.md`

2. **Undo**: Keeps processing log for manual undo
   - Location: `3.Archives/Processing Logs/YYYY-MM-DD-process.json`

3. **Confidence Thresholds**:
   - High confidence (>90%): Auto-route
   - Medium (70-90%): Suggest with explanation
   - Low (<70%): Ask user for destination

## Workflow Integration

### Daily Capture → Weekly Process
```
Monday-Thursday:
- Quick capture to inbox (phone, desktop)
- Don't worry about organization

Friday:
1. /inbox-process
2. Review routed items
3. Expand important notes
4. Clear any remaining
```

### Combine with Weekly Review
```
Friday 4pm workflow:
1. /inbox-process         # Clear inbox
2. /weekly-review          # Review week
3. /blogresearcher [topic] # Draft content
4. Close laptop           # Weekend starts
```

## Custom Routing Rules

Edit `.opencode/processing-rules.md` to customize:

```markdown
# Custom Inbox Processing Rules

## Work Projects
Keywords: "alaska", "work project", "team meeting"
Destination: 2.Areas/Work Notes/
Tags: #work

## Personal Finance
Keywords: "budget", "expense", "investment"
Destination: 2.Areas/Personal Home/Finance/
Tags: #finance

## Property Management
Keywords: "rental", "property", "tenant"
Destination: 2.Areas/Personal Home/Real-estate/
Tags: #property
```

## Tips

1. **Inbox Zero Weekly**: Run `/inbox-process` every Friday
2. **Quick Capture**: Use inbox for speed, process for organization
3. **Trust the System**: Let AI route; correct only when needed
4. **Review Routes**: First few times, use `--dry-run` to verify logic
5. **Add Context**: More context in captures = better routing

## Troubleshooting

**Items not routing correctly**
→ Add more keywords to capture
→ Edit custom routing rules
→ Use interactive mode to train system

**Too many items in inbox**
→ Run daily instead of weekly
→ Use `/inbox-quick-clear` for rapid triage

**Processing too slow**
→ Reduce batch size: `/inbox-process --limit=10`
→ Process by category: `/inbox-process --filter=work`

---

**Recommended Schedule:**
```
Every Friday at 3pm (before weekly review):
/inbox-process
```

Keeps your Second Brain organized with zero friction. 🗂️
