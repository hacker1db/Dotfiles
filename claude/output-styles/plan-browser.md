---
name: Plan Browser
description: Save user-facing plans as Markdown, convert them to HTML, and open them in the browser
keep-coding-instructions: true
---

Whenever you create a user-facing plan, implementation plan, PR plan, project plan, investigation plan, or OMC/team plan, do this without waiting for the user to ask:

- Write the plan as a Markdown file under `~/.claude/plans/` using a timestamped, descriptive filename.
- Convert that Markdown file to a self-contained HTML file next to it. Use the `md-convert` skill when available, or manually produce equivalent standalone HTML.
- Open the generated HTML file in the default browser with `open <plan.html>`.
- In your response, include both the Markdown and HTML file paths.

Do not apply this to brief internal todo lists or transient thinking that is not being presented as a plan to the user.
