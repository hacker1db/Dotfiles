# Briefing contract

Apply the evidence rules in the root before adapting these examples. Say finished or new only when event data supports that claim. Count lifetime highlights separately from highlights created during the window.

## Step 3: Classify Annotations

For each annotated document, scan the user's notes on highlights and the document-level notes field. Flag anything actionable:

| Flag | Pattern |
|------|---------|
| Question | Contains "?" or asks something |
| TODO | Says to look up, verify, follow up, try, or do something |
| Idea | Connects multiple concepts or proposes something new |
| Disagreement | Pushes back on the source's claim |
| Cross-reference | Mentions another book, article, or author by name |

Annotations that don't match any pattern are just context — the user thinking out loud. Still include them in the briefing.

## Step 4: Write the Briefing

Write a conversational recap — like a well-read assistant catching someone up over coffee. Warm, concise, and useful. Not a data dump.

**Structure:**

1. **Opening line** — a one-sentence overview of the time period.

   "You had a busy week — 12 articles and a book, mostly history and AI stuff."

   "Quiet day — just two articles, but you had a lot to say about one of them."

2. **Per-document paragraphs** — one short paragraph per annotated document, ordered by engagement (most annotated first). Each paragraph should naturally weave together:
   - What the piece was about (1 sentence)
   - How much the user highlighted (folded into the flow, not as a stat line)
   - The most interesting annotations, especially actionable ones — paraphrase the user's notes conversationally:
     "You had a question about whether this applies to mammals too."
     "You noted you want to try this workflow yourself."
     "You pushed back on the author's claim about pricing."
   - If the user left a document-level note, lead with it — it's usually the overall reaction

3. **Light reads** — a single sentence listing documents the user highlighted but didn't annotate. "You also highlighted a few things in [Title] and [Title] but didn't leave notes."

4. **Action items** — if any annotations were flagged as TODOs, questions, or ideas, collect them at the end as a short numbered list under "**Things you might want to follow up on:**". Skip this section entirely if nothing is actionable.

**Example output:**

```
Busy couple of days — you reviewed notes on 8 articles and that Ottoman
history book. Most of your attention went to the logistics stuff.

You were really into Sarah Chen's piece on supply chain resilience. 14
highlights, and you left a note saying the comparison to Roman grain
logistics was "exactly what I've been looking for." You also flagged a
question — whether the same bottleneck pattern shows up in digital
infrastructure.

The Ottoman book has 9 highlights across three chapters. Your note on
the harem education system connected it to that article about elite
training programs you read last month. You also marked a claim about
succession rates that you want to verify.

You also highlighted a few things in "Why Bridges Fail" and a Substack
post about medieval farming, but didn't leave notes on either.

**Things you might want to follow up on:**
1. Does the supply chain bottleneck pattern apply to digital infrastructure?
2. Verify the Ottoman succession rate claim (Chapter 7)
3. You wanted to connect harem education to the elite training piece
```

**Tone rules:**
- Second person ("you read", "you noted"), not third person
- Contractions are fine
- No bullet-point lists for the main body — prose paragraphs only
- Keep it skimmable — short paragraphs, one idea each
- Don't editorialize on the content itself — just report what the user did and said
- The action items list at the end is numbered — that's the one exception
- If the persona file exists, use it to add context (e.g. "this connects to your interest in X")
