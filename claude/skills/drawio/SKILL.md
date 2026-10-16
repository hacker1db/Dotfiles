---
name: drawio
description: "Create or revise editable draw.io diagrams for architecture, networks, and data flows. Use for .drawio source files or PNG exports with embedded diagram XML. Generic image generation, charts, and diagram explanations are separate tasks."
---

# Draw.io Diagrams

Deliver valid `.drawio` XML and, when PNG output is requested, a rendered PNG with embedded source XML that can reopen in draw.io.

## Workflow

1. Identify diagram type, systems, requested output format, metadata, and source repository. Read `references/template-structure.md` and `references/component-styles.md` for the diagram contract. Mark unknown source or metadata fields explicitly; never invent repository URLs.
2. Generate `.drawio` XML in the requested or project appropriate destination. Validate XML structure and references.
3. Discover the available rendering capability, such as draw.io export or a browser plus rendering helper. Use configured helper paths when present. Read `references/rendering.md` only when rendering or embedding is required.
4. Render requested PNG output and embed its XML. A screenshot alone is not an editable diagram. Inspect the PNG metadata or reopen it in draw.io to verify embedded XML, and inspect the visual result for clipping and unreadable labels.
5. Link the source and requested export. If rendering or embedding is unavailable, deliver the source, identify the missing capability, and state that the requested editable PNG remains incomplete. Never rename XML or HTML as PNG or claim an unverified screenshot is editable.

## Template rules

Date: `YYYY-MM-DD`. Title and CONFIDENTIAL font: 40px. Include all four corners and the complete legend. Omit a Version metadata field. Include a verified source repository link when available, or an explicit source placeholder.

| Region | X range | Y range |
|--------|---------|---------|
| Diagram content | `-1500` to `-250` | `80` to `800` |
| Legend / metadata | `-200` to `160` | `80` to `820` |
| CONFIDENTIAL watermark | x=`-1540` | y=`840` |
| Source link | x=`-1540`, width=`810` | y=`890` |
