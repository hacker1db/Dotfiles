# Vault outputs

Resolve `<vault>` and the user's local date from the session context. Sanitize the topic for filenames without changing the displayed title. Match existing frontmatter conventions, including id, aliases, tags, creation date, and modification date.

## Learning note

Save `<vault>/[TOPIC] - 30 Min Learn - [YYYY-MM-DD].md` in Title Case. Include these sections in order: What is it?, Why it matters, How it works, Real example, The aha insight, Go deeper, Concept Diagram, Quiz results, Sources, and Related. Summarize the actual taught content and preserve source URLs. Go deeper contains one strongest source. Embed `![[TOPIC - 30 Min Learn - YYYY-MM-DD.excalidraw.md]]` when that diagram exists, or link the standalone fallback. Record each quiz question and the user's actual answer with feedback. Link `[[Learning Index]]` only when it exists.

## Glossary

Update `<vault>/Learning Glossary.md`. Reuse existing definitions and append new terms in alphabetical order as `**Term**: plain English definition`. Create the glossary with matching frontmatter and a Learning Glossary heading if absent. If a definition is materially wrong, explain the correction instead of propagating it silently.

## Daily note

Use `<vault>/0.Quick Notes 📨/Daily Stuff/YYYY-MM-DD.md`. Insert `Learned: [[TOPIC - 30 Min Learn - YYYY-MM-DD]]` into its existing learning section or appropriate existing notes section, without duplicating a link or inventing a new top level section against vault instructions. If missing, create the daily note from the user's existing template. If the template cannot be found, report the missing link step rather than inventing a daily note structure.

## Diagram and completion

Use `diagram.md` for the `.excalidraw.md` structure and actual mechanism steps. Parse the embedded JSON to verify it and check text IDs, element bindings, and note embed targets. If the Excalidraw plugin is unavailable, save the same drawing as valid standalone `.excalidraw` JSON in the vault and link it from the note. Report the three verified paths: learning note, daily note, and diagram. Do not claim visual rendering was verified without opening a supported renderer.
