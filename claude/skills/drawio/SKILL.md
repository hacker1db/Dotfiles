---
name: drawio
description: "Create editable draw.io diagrams and PNG exports. Triggers: drawio, .drawio, architecture diagram, network diagram, data flow diagram."
---

# Draw.Io Skill

Generates standard diagrams as **editable PNG files** — PNGs with embedded XML reopenable in draw.io.

## Workflow

1. Identify: diagram type, systems, metadata (team, SME, year), and GitHub source path
2. Generate `.drawio` XML — see `references/component-styles.md` for all element styles
3. Install deps if needed: `cd $HOME/.dotfiles/claude/drawio-scripts && npm install`
4. Render preview HTML: `node $HOME/.dotfiles/claude/drawio-scripts/render_drawio_html.js /tmp/diagram.drawio /tmp/diagram.html 0`
5. If a PNG screenshot is produced from the HTML preview, embed source XML with: `node $HOME/.dotfiles/claude/drawio-scripts/embed_xml.js /tmp/diagram.png /tmp/diagram.drawio /tmp/diagram.editable.png`

## Coordinate System

| Region | X range | Y range |
|--------|---------|---------|
| Diagram content | `-1500` to `-250` | `80` to `800` |
| Legend / metadata | `-200` to `160` | `80` to `820` |
| CONFIDENTIAL watermark | x=`-1540` | y=`840` |
| GitHub source link | x=`-1540`, width=`810` | y=`890` |

## Critical Rules

Date: `YYYY-MM-DD` · Title/CONFIDENTIAL font: 40px · All 4 corners required · Copy ALL legend cells verbatim · No `Version` field in metadata · GitHub link is required.

## References

- `references/component-styles.md` — Full XML: outer wrapper, chrome, legend, components, arrows, step callouts
- `references/template-structure.md` — Diagram types, page sizes, color legend, node styles
