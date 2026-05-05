---
name: drawio
description: >
  Create, generate, and render draw.io diagram files (.drawio) as editable PNG images using the
  standard template. Use this skill whenever the user asks to create a technical
  diagram, network diagram, architecture diagram, PCI flow diagram, data flow diagram, content
  security policy (CSP) diagram, subresource integrity (SRI) diagram, or any diagram that should
  be editable in draw.io. Always use this skill when diagrams, drawio, or .drawio files are involved.
---

# Draw.Io Skill

Generates standard diagrams as **editable PNG files** — PNGs with embedded XML reopenable in draw.io.

## Workflow

1. Identify: diagram type, systems, metadata (team, SME, year), and GitHub source path
2. Generate `.drawio` XML — see `references/component-styles.md` for all element styles
3. Install deps if needed: `cd scripts && npm install`
4. Render: `node scripts/render_drawio.js /tmp/diagram.drawio /tmp/diagram.png 0`

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
