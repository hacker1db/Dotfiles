---
name: exec-brief
description: "Write a leadership brief in the standard Exec Summary format. Triggers: exec brief, leadership brief, brief the team, draft a brief."
argument-hint: [situation, incident, or topic to write up]
---

# Exec Brief

## Purpose

Produce a short, polished leadership write-up from the user's context. The format is fixed so readers can scan it the same way every time. The output is high-level — executives should be able to read it in under two minutes.

## When to invoke

1. The user says "exec brief", "leadership brief", "brief leadership", "write up for leadership", or similar.
2. The user has an incident, outage, escalation, risk, or project situation they need to communicate upward.
3. The user has rough notes or a brain dump they want shaped into the standard format.
4. The user asks to update an existing brief — edit relevant sections in place, do not regenerate.

## How to operate

1. If `$ARGUMENTS` or the user's message contains enough context (who, what, impact, actions, ask), write the brief immediately. Do not interview unnecessarily.
2. If critical facts are missing that would leave a section blank, ask for them in a single message — all gaps at once, never one at a time.
3. After writing, present the full document in a fenced markdown block ready to copy.

**Critical facts needed to write the brief:**
- What happened and when
- Who or what is affected and how
- What is being done about it
- What leadership needs to decide or provide (if anything)

If any of these are missing, ask for them before writing.

## Output template

Use this structure exactly. Order is load-bearing — do not rearrange. Do not add sections.

The **Ask** section is optional — include it only when there is something concrete to request (decision, resource, owner, deadline). Omit the heading entirely if there is nothing to ask.

```markdown
# <Brief Title> — <Date>

> **Status:** <Active | Contained | Resolved | Monitoring>
> **Audience:** <e.g. Engineering Leadership | CISO | VP>
> **Prepared by:** David Walters

---

## Executive Summary
<Three to five sentences. What it is, who it affects, and the one thing leadership must know. End with what is being done and what is needed from them.>

## What Happened
<A short paragraph or two. When it was detected, where it lives, root cause (or suspected cause if still under investigation). Plain language — no jargon.>

## Impact
<One sentence on blast radius. Then a short numbered list of consequences ordered worst first. Include affected user counts, systems, and any SLA or compliance implications. State whether impact is ongoing or contained.>

## Action
<Numbered list. Each item: what is being done and who owns it by when. Include immediate steps already taken, what is in progress now, and the next milestone.>

## Ask
<Numbered list of what we need from leadership — specific decision, resource, or owner, and the date we need it by. Omit this section entirely if there is nothing concrete to request.>
```

## Style rules

1. No em-dashes in sentences. Use commas, semicolons, or short sentences.
2. Lead each section with the most important fact. Executives skim.
3. Be specific about numbers, times, and owners — "some users" and "earlier today" are not useful.
4. When root cause is not confirmed, say "suspected" or "under investigation." Do not write as if it is confirmed.
5. Short is better. This is a brief, not a post-mortem.

## Updating an existing brief

Edit in place — do not regenerate from scratch.
1. Update the Status field in the header.
2. Prepend a short **Update — \<datetime\>** line at the top of any changed section.
