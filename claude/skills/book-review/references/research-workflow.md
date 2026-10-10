# Research workflow

## Setup

1. **Check for persona file.** Read `reader_persona.md` in the current working directory if it exists. Use it to understand the user's interests, reading goals, and voice; this shapes the review's framing, what connections to prioritize, and what the user is likely to care about. If no persona file exists, proceed without it and ask the user about their purpose for reading the book if it's not obvious from their highlights.

2. **Parse the argument** as a book title or search term.

```
/book-review Merchant Kings
/book-review 7 Powers
```

---

## Phase 1: Pull the Book's Highlights

### 1.1 Find the book

Search Reader for the target book:

Use the selected authenticated Reader capability to search the title, initially filtering to EPUB and PDF if supported.

If no results, broaden to all categories. If multiple matches, list them and ask the user to pick.

### 1.2 Get highlights

Fetch the selected book's highlights and annotations using that capability.

Read and count the available highlights. If fewer than ten, state the evidence limit and scale the draft accordingly. Do not block a requested draft solely because its source set is small.

### 1.3 Get the full document details

Fetch the selected book's metadata using that capability.

Pull title, author, summary, cover image. You'll need these for the final output.

---

## Phase 2: Extract Claims

Process every highlight into an atomic claim. This is the step that turns
"I highlighted this paragraph" into structured, searchable research material.

For each highlight:

1. Read the highlighted text and any user note/annotation
2. Write a single present-tense declarative claim (under 10 words when possible)
3. If the user left a note, weight the claim toward what the note focused on

**Claim quality standards:**

Good claims are specific, searchable facts or assertions:
- "chimney sweeps died of scrotal cancer from coal soot"
- "Ottoman harem trained slave girls as elite bureaucrats"
- "monsoon winds enabled global maritime trade"

Bad claims are vague or generic:
- "coal mining had health consequences"
- "the author discusses Ottoman succession"
- "interesting point about slavery"

**After processing all highlights**, review the full list. Reject and rewrite any that are:
- Generic/boring ("author discusses X")
- Duplicative (two claims saying the same thing differently; consolidate)
- Vague (doesn't stand alone without reading the highlight)

Store the claims as a working list grouped by theme. This becomes your outline.

---

## Phase 3: Search the Library for Related Material

This is what makes the review more than a summary. For each major theme cluster
from Phase 2, search the user's full Reader library for related content.

### 3.1 Theme-based searches

For each theme cluster (aim for 3-6 themes):

Search the library for theme keywords, limiting the first pass to about twenty matches when supported.

Pull highlights from the top hits:

Fetch highlights for relevant related documents.

You're looking for:
- **Supporting evidence** from other sources that strengthens a claim
- **Contradictions** that complicate the book's argument
- **Parallel examples** from different domains (the user read about X in biology, the book says the same about economics)
- **The user's own prior thinking** visible in their notes/annotations on related docs

### 3.2 Author search

Search the library for other work by the book's author.

Check if the user has read other work by the same author. Prior context enriches the review.

### 3.3 Extract related claims

For each relevant highlight from a related document, extract a claim the same way
as Phase 2. Tag it with its source document so you can cite it properly.

**Result:** You should now have:
- The book's claims (Phase 2), grouped by theme
- Related claims from the broader library (Phase 3), mapped to those same themes
- A sense of where the user's reading supports, complicates, or extends the book

---

## Phase 4: Supplement with Web Research

Fill gaps that the user's library doesn't cover. Keep this focused; the library
research is the core, web research is supplemental.

- Search for academic sources, author interviews, other reviews
- Look for Substack writers or bloggers covering the same topic

---
