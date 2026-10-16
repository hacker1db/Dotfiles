---
name: learn-it
description: "Run a requested structured learning session of about 30 minutes, with sourced explanations, a quiz, an Excalidraw concept diagram, and Obsidian notes. Use for learn-it or an explicit guided learning session. A brief explanation, standalone ELI5 answer, or walkthrough of code does not imply this full workflow."
argument-hint: "[topic you want to learn]"
---

# Structured learning session

Teach one topic through what it is, why it matters, how it works, a real example, a key insight, and a quiz. Preserve the user's preferred pace. The complete session creates a learning note, concept diagram, glossary updates, and a daily note link.

## Inputs and continuity

1. Resolve the topic from the request. Ask for it only when missing. Capture a mission from a supplied goal or `--why`; do not ask for a mission when none was supplied.
2. Resolve the configured vault, defaulting to `~/notes/SecondBrain`, and use the user's local date. Read applicable vault instructions and its existing daily note template before writing.
3. Search accessible prior `*30 Min Learn*.md` notes for related topics. If one is older than a few days, prepare one short recall question. Skip silently when none exists; report inaccessible storage only if it prevents a promised output.
4. Read existing `Learning Glossary.md` definitions for terms you plan to teach, so explanations remain consistent.

## Research and teaching

Read `references/session.md` before researching and teaching. Use available search and page reading capabilities to ground the lesson in trusted sources. Prefer Microsoft Learn for Microsoft and Azure topics, each technology's official documentation for other software, and appropriate primary sources for other domains. Keep citations and one best resource for deeper reading. If research is unavailable, use supplied trusted material and explain the limitation; ask for source material when necessary. Never invent research or sources.

Present the roadmap, then teach interactively at the user's pace. An explicit request to begin is sufficient to start; do not add a redundant ready check. Wait for answers at practice and quiz steps, and do not fabricate responses. Explain jargon, use concrete analogies, and introduce one concept at a time. Adapt pauses and detail to the user's directions.

## Save and verify

After the quiz, read `references/diagram.md` to create the concept diagram, then `references/vault-output.md` to save the note, update the glossary, and add the daily note link. Those references contain the required formats and fallbacks. If the user ends early, save only when requested and mark unanswered quiz items and incomplete sections accurately.

Verify each created file, the diagram JSON, and wiki link targets before reporting saved outputs. Report partial completion accurately if a required capability is unavailable. Keep this a single session; do not add a separate learning workspace or HTML lesson system.
