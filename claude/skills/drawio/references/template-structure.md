# Draw.Io — Template Structure Reference

## Diagram Types (4 Pages In AAG Standard Template)

| Page | Purpose |
|------|---------|
| Technical Diagram | Network / architecture diagrams |
| PCI Flow Diagram | Payment card data flow |
| Content Security Policy | Browser security headers |
| Subresource Integrity | SRI documentation |

## Page Sizes

| Diagram Type | Width | Height |
|---|---|---|
| Technical Diagram | 827 | 1169 (A4 portrait) |
| PCI Flow Diagram | 827 | 1169 (A4 portrait) |
| Content Security Policy | 850 | 1100 |
| Subresource Integrity | 850 | 1100 |

## Required Metadata Fields

All diagrams must include in the metadata cell:
- **Team Name** — your team's name
- **SME** — Subject Matter Expert's full name
- **Copyright** — `<CompanyName>, Inc YEAR`
- **Last Reviewed Date** — `yyyy-mm-dd` (full ISO, never shorten)

## Color Legend

| Color | Meaning | Fill | Stroke |
|-------|---------|------|--------|
| Green semi-transparent | Environment / boundary | `#d5e8d4` | `#82b366` |
| Yellow dashed | Server Farm | `#FFF4CF` | `#b88624` |
| Yellow dotted | P2PE Token / 3rd Party | `#ffdb67` | `#e5ad07` |
| Red crosshatch outline | CDE System boundary | none | `#FF0000` |
| Pink / Red | CDE Systems | `#f8cecc` | `#b85450` |
| Orange | Connected System | `#ffe6cc` | `#d79b00` |
| Purple | Out of Scope System | `#e1d5e7` | `#9673a6` |
| Default / White | Other Internal System | default | default |

## Arrow / Line Types

| Style | Meaning |
|-------|---------|
| Blue open arrow (`#6c8ebf`) | Encrypted HTTPS / SSL/TLS 1.2 |
| Green open arrow (`#82b366`) | Encrypted other traffic |
| Orange/red dashed | Unencrypted or P2PE data flow |
| Dark olive oval end | Comment indicator |
| Gray line (no arrow) | Dedicated/private unencrypted line |

## Coordinate Positioning Convention

```
x: -1560          x: -250   x: -200   x: 160    x: 320
|                 |         |         |          |
|  DIAGRAM        |         | LEGEND  |          |
|  CONTENT        |         | y=230+  |          |
|  (systems,      |         |         |          |
|   flows, zones) |         |         |          |
|                 |         |         |          |
y=840  CONFIDENTIAL (x=-1540)
y=890  GitHub source link (x=-1540, width=810)
```

## HTML Entities In Label Values

| Use | Entity |
|-----|--------|
| `<` | `&lt;` |
| `>` | `&gt;` |
| `&` | `&amp;` |
| `"` inside attribute | `&quot;` |
