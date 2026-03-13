---
description: Create, generate, and render draw.io diagrams (.drawio) using the standard corporate template. Use for architecture, network, PCI flow, CSP, SRI, or any technical diagram.
---
# Draw.io Diagram Skill

Generate corporate-standard draw.io diagrams as **editable PNG files** — PNGs that contain the full XML embedded so they can be reopened and edited in draw.io.

**CLI tool**: `/opt/homebrew/bin/cli-anything-drawio` — stateful Draw.io CLI for creating diagrams, adding shapes/connectors, and exporting to PNG/PDF/SVG.
**Scripts location**: `~/.dotfiles/claude/drawio-scripts/`
**Template location**: `~/.dotfiles/claude/drawio-assets/template/template.drawio`

## Workflow

1. Understand the diagram request
2. Build the diagram using the CLI tool (preferred) or generate raw .drawio XML
3. Export to editable PNG
4. Present the file to the user

## Step 1 — Understand the Request

Identify:
- **Application name**: The name of the application or service being diagrammed. If not provided, ask the user.
- **Systems/components** to include
- **Metadata**: team name, team email, SME name, year, review date
- **Data flows**: what connects to what, and what kind of traffic
- **GitHub source path**: the repo path where this diagram lives. **Always use the `main` branch** in the URL (e.g. `{ORG}/{REPO}/tree/main/diagrams/my-diagram.drawio`) — never use a feature branch or commit SHA.

If critical info is missing (e.g., no systems listed), ask once. For metadata, use placeholders if not provided. When invoked from `/runbook`, the team email will be passed in the prompt — use it in the metadata block.

## Step 2 — Build the Diagram

### Primary method: CLI tool (preferred — no temp files)

Copy the corporate template to the target location, then use the CLI to update metadata and add diagram content:

```bash
# 1. Copy template to working location
cp ~/.dotfiles/claude/drawio-assets/template/template.drawio docs/diagrams/<application-name>.drawio

# 2. Update title and metadata (these IDs exist in the template)
CLI="/opt/homebrew/bin/cli-anything-drawio"
$CLI --json --project docs/diagrams/<application-name>.drawio shape label title "My Diagram Title"
$CLI --json --project docs/diagrams/<application-name>.drawio shape label metadata "Team Name: Security<br>Team Email: team@example.com<br>SME: Jane Doe<br>Copyright: [COMPANY], Inc 2026<br>Last Reviewed Date: 2026-03-12"

# 3. Add shapes (diagram content area uses x: -1500 to -250, y: 80 to 800)
$CLI --json --project docs/diagrams/<application-name>.drawio shape add rectangle -l "Web App" --x -1200 --y 200 -w 120 -h 60
# ... add more shapes, then connect them
$CLI --json --project docs/diagrams/<application-name>.drawio connect add <source_id> <target_id> --style orthogonal -l "HTTPS"

# 4. Save
$CLI --json --project docs/diagrams/<application-name>.drawio project save
```

**Available shape types**: `rectangle`, `rounded`, `ellipse`, `diamond`, `triangle`, `hexagon`, `cylinder`, `cloud`, `parallelogram`, `process`, `document`, `callout`, `note`, `actor`, `text`

**Available edge styles**: `straight`, `orthogonal`, `curved`, `entity-relation`

**Styling shapes/connectors** after creation:
```bash
$CLI --json --project docs/diagrams/<application-name>.drawio shape style <cell_id> fillColor "#f8cecc"
$CLI --json --project docs/diagrams/<application-name>.drawio shape style <cell_id> strokeColor "#b85450"
$CLI --json --project docs/diagrams/<application-name>.drawio connect style <connector_id> strokeColor "#6c8ebf"
```

### Fallback method: Raw XML generation

Use this when the CLI tool cannot express the needed layout or when precise XML control is required.

### Coordinate System

The corporate template uses **negative x coordinates** for the right-side panel (legend/metadata) and **positive/negative x** for the main diagram area. The coordinate origin is near the top-center of the canvas.

```
x: -1560     x: -1480          x: -200    x: 160   x: 240   x: 320
|             |                 |          |        |        |
| DIAGRAM     |                 | LEGEND   |        | CORNER |
| CONTENT     |                 | y=230+   |        | MARKS  |
|             |                 |          |        |        |
y=840 CONFIDENTIAL + GitHub link
```

**Diagram content**: Use x range roughly -1500 to -250, y range 80 to 800
**Legend/metadata panel**: x range -200 to 160, y range 80 to 820
**Corner markers**: at corners of the full canvas

### Template Outer Wrapper

```xml
<mxfile host="Electron" version="27.0.9">
  <diagram id="[UNIQUE_ID]" name="[DIAGRAM_NAME]">
    <mxGraphModel dx="3073" dy="889" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- content here -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

### Mandatory Chrome Elements (copy verbatim into every diagram)

**Corner print margin markers** — all 4 required:
```xml
<mxCell id="corner-tl" value="" style="endArrow=none;html=1;rounded=0;strokeColor=#B2B2B2;" parent="1" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="-1560" y="120" as="sourcePoint"/><mxPoint x="-1480" y="40" as="targetPoint"/>
    <Array as="points"><mxPoint x="-1560" y="40"/></Array>
  </mxGeometry>
</mxCell>
<mxCell id="corner-tr" value="" style="endArrow=none;html=1;rounded=0;strokeColor=#B2B2B2;" parent="1" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="238" y="40" as="sourcePoint"/><mxPoint x="318" y="120" as="targetPoint"/>
    <Array as="points"><mxPoint x="318" y="40"/></Array>
  </mxGeometry>
</mxCell>
<mxCell id="corner-bl" value="" style="endArrow=none;html=1;rounded=0;strokeColor=#B2B2B2;" parent="1" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="-1480" y="921" as="sourcePoint"/><mxPoint x="-1560" y="841" as="targetPoint"/>
    <Array as="points"><mxPoint x="-1560" y="921"/></Array>
  </mxGeometry>
</mxCell>
<mxCell id="corner-br" value="" style="endArrow=none;html=1;rounded=0;strokeColor=#B2B2B2;" parent="1" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="240" y="920" as="sourcePoint"/><mxPoint x="320" y="840" as="targetPoint"/>
    <Array as="points"><mxPoint x="320" y="840"/></Array>
  </mxGeometry>
</mxCell>
```

**Title** (top of right panel, fontSize=40):
```xml
<mxCell id="title" value="[DIAGRAM TITLE]" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=40;fontColor=#000000;opacity=75;" parent="1" vertex="1">
  <mxGeometry x="-192" y="80" width="510" height="60" as="geometry"/>
</mxCell>
```

**Metadata block** (below title, NO Version field):
```xml
<mxCell id="metadata" value="Team Name: [TEAM]&lt;br&gt;Team Email: [EMAIL]&lt;br&gt;SME: [SME]&lt;br&gt;Copyright: [COMPANY], Inc [YEAR]&lt;br&gt;Last Reviewed Date: [YYYY-MM-DD]" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=14;fontColor=#000000;opacity=75;" parent="1" vertex="1">
  <mxGeometry x="-192" y="140" width="440" height="100" as="geometry"/>
</mxCell>
```

**Legend border lines** (L-shaped, top and left of legend box):
```xml
<mxCell id="legend-border-v" value="" style="endArrow=none;html=1;rounded=0;fontSize=14;fontColor=#000000;strokeColor=#726E6C;" parent="1" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="-202" y="230" as="sourcePoint"/><mxPoint x="-200" y="820" as="targetPoint"/>
  </mxGeometry>
</mxCell>
<mxCell id="legend-border-h" value="" style="endArrow=none;html=1;rounded=0;fontSize=14;fontColor=#000000;strokeColor=#726E6C;" parent="1" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="-200" y="230" as="sourcePoint"/><mxPoint x="160" y="230" as="targetPoint"/>
  </mxGeometry>
</mxCell>
```

**Full legend items** (copy all verbatim):
```xml
<!-- Environment swatch (green) -->
<mxCell id="leg-env-swatch" value="" style="rounded=1;whiteSpace=wrap;html=1;fontSize=12;strokeColor=#5e8741;fillColor=#c0e585;arcSize=5;opacity=33;" parent="1" vertex="1">
  <mxGeometry x="-191.76" y="244" width="40" height="10" as="geometry"/>
</mxCell>
<mxCell id="leg-env-label" value="Environment" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-141.76" y="239" width="140" height="20" as="geometry"/>
</mxCell>

<!-- 3rd-Party/External System swatch (yellow dotted) -->
<mxCell id="leg-p2pe-swatch" value="" style="rounded=0;whiteSpace=wrap;html=1;fontSize=10;strokeColor=#e5ad07;strokeWidth=1;fillColor=#ffdb67;opacity=75;dashed=1;dashPattern=1 1;" parent="1" vertex="1">
  <mxGeometry x="-191.76" y="264" width="40" height="10" as="geometry"/>
</mxCell>
<mxCell id="leg-p2pe-label" value="3rd-Party or External System" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-142.9" y="259" width="140" height="20" as="geometry"/>
</mxCell>

<!-- Logical System Grouping / CDE boundary (red crosshatch) -->
<mxCell id="leg-cde-swatch" value="" style="rounded=1;whiteSpace=wrap;html=1;fontSize=12;strokeWidth=2;fillColor=none;" parent="1" vertex="1">
  <mxGeometry x="-191.76" y="282" width="40" height="10" as="geometry"/>
</mxCell>
<mxCell id="leg-cde-border-1" value="" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0;entryDx=0;entryDy=0;exitX=1;exitY=1;exitDx=0;exitDy=0;fillColor=#f8cecc;strokeColor=#FF0000;" parent="1" source="leg-cde-swatch" target="leg-cde-swatch" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="-163.14" y="297" as="sourcePoint"/><mxPoint x="-113.14" y="247" as="targetPoint"/>
  </mxGeometry>
</mxCell>
<mxCell id="leg-cde-border-2" value="" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=1;entryDx=0;entryDy=0;exitX=1;exitY=0;exitDx=0;exitDy=0;fillColor=#f8cecc;strokeColor=#FF0000;" parent="1" source="leg-cde-swatch" target="leg-cde-swatch" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="-141.76" y="292" as="sourcePoint"/><mxPoint x="-181.76" y="282" as="targetPoint"/>
  </mxGeometry>
</mxCell>
<mxCell id="leg-cde-label" value="Logical System Grouping" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-141.76" y="277" width="140" height="20" as="geometry"/>
</mxCell>

<!-- Encrypted HTTPS arrow (blue) -->
<mxCell id="leg-https-arrow" value="" style="endArrow=openThin;html=1;rounded=0;endFill=0;strokeWidth=2;fillColor=#dae8fc;strokeColor=#6c8ebf;" parent="1" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="-192" y="308" as="sourcePoint"/><mxPoint x="-152" y="308" as="targetPoint"/>
  </mxGeometry>
</mxCell>
<mxCell id="leg-https-label" value="Encrypted Traffic (SSL/TLS 1.2/HTTPS, Port 443)" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-142" y="299" width="232" height="19" as="geometry"/>
</mxCell>

<!-- Comment indicator (dashed oval-end) -->
<mxCell id="leg-comment-arrow" value="" style="endArrow=oval;html=1;rounded=0;endFill=0;strokeWidth=1;fillColor=#dae8fc;strokeColor=default;dashed=1;" parent="1" edge="1">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="-192" y="328" as="sourcePoint"/><mxPoint x="-152" y="328" as="targetPoint"/>
  </mxGeometry>
</mxCell>
<mxCell id="leg-comment-label" value="Comment indicators" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-142" y="319" width="232" height="19" as="geometry"/>
</mxCell>

<!-- CDE Systems (pink) -->
<mxCell id="leg-cde-server" value="" style="verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=#b85450;fillColor=#f8cecc;shape=mxgraph.azure.server_rack;" parent="1" vertex="1">
  <mxGeometry x="-166.93" y="358" width="12.38" height="15" as="geometry"/>
</mxCell>
<mxCell id="leg-cde-actor" value="" style="shape=actor;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;" parent="1" vertex="1">
  <mxGeometry x="-190" y="358" width="9.76" height="15" as="geometry"/>
</mxCell>
<mxCell id="leg-cde-sys-label" value="CDE Systems" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-138.86" y="360" width="140" height="10" as="geometry"/>
</mxCell>

<!-- Connected System (orange) -->
<mxCell id="leg-conn-server" value="" style="verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=#d79b00;fillColor=#ffe6cc;shape=mxgraph.azure.server_rack;" parent="1" vertex="1">
  <mxGeometry x="-166.93" y="381" width="12.38" height="15" as="geometry"/>
</mxCell>
<mxCell id="leg-conn-actor" value="" style="shape=actor;whiteSpace=wrap;html=1;fillColor=#ffe6cc;strokeColor=#d79b00;" parent="1" vertex="1">
  <mxGeometry x="-190" y="381" width="9.76" height="15" as="geometry"/>
</mxCell>
<mxCell id="leg-conn-sys-label" value="Connected System" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-138.86" y="383" width="140" height="10" as="geometry"/>
</mxCell>

<!-- Out Of Scope System (purple) -->
<mxCell id="leg-oos-server" value="" style="verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=#9673a6;fillColor=#e1d5e7;shape=mxgraph.azure.server_rack;" parent="1" vertex="1">
  <mxGeometry x="-166.93" y="407" width="12.38" height="15" as="geometry"/>
</mxCell>
<mxCell id="leg-oos-actor" value="" style="shape=actor;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;" parent="1" vertex="1">
  <mxGeometry x="-190" y="407" width="9.76" height="15" as="geometry"/>
</mxCell>
<mxCell id="leg-oos-sys-label" value="Out Of Scope System" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-138.86" y="409" width="140" height="10" as="geometry"/>
</mxCell>

<!-- Other Internal System (default colors) -->
<mxCell id="leg-other-server" value="" style="verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;shape=mxgraph.azure.server_rack;" parent="1" vertex="1">
  <mxGeometry x="-166.93" y="433" width="12.38" height="15" as="geometry"/>
</mxCell>
<mxCell id="leg-other-actor" value="" style="shape=actor;whiteSpace=wrap;html=1;" parent="1" vertex="1">
  <mxGeometry x="-190" y="433" width="9.76" height="15" as="geometry"/>
</mxCell>
<mxCell id="leg-other-sys-label" value="Other Internal System (See other diagram)" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-138.86" y="435" width="208.62" height="10" as="geometry"/>
</mxCell>
```

**CONFIDENTIAL watermark** (bottom-left, fontSize=40):
```xml
<mxCell id="confidential" value="CONFIDENTIAL" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=40;fontColor=#7A1D2F;opacity=75;" parent="1" vertex="1">
  <mxGeometry x="-1540" y="840" width="340" height="70" as="geometry"/>
</mxCell>
```

**GitHub source link** (below CONFIDENTIAL — REQUIRED, use UserObject with clickable link):
```xml
<UserObject label="&lt;font color=&quot;#666666&quot;&gt;Source: https://github.com/[ORG]/[REPO]/tree/main/diagrams/[FILE].drawio&lt;/font&gt;" link="https://github.com/[ORG]/[REPO]/tree/main/diagrams/[FILE].drawio" id="github-source">
  <mxCell style="text;whiteSpace=wrap;html=1;" parent="1" vertex="1">
    <mxGeometry x="-1540" y="890" width="810" height="20" as="geometry"/>
  </mxCell>
</UserObject>
```

### Flow Step Numbered Callouts

Use on diagram arrows and in the legend step list:
```xml
<mxCell id="step-1" value="&lt;p style=&quot;line-height: 100%;&quot;&gt;1&lt;/p&gt;" style="ellipse;whiteSpace=wrap;html=1;aspect=fixed;spacing=0;spacingLeft=1;fillColor=#c0f7ff;strokeColor=#00cff0;strokeWidth=3;fontColor=#01426A;" parent="1" vertex="1">
  <mxGeometry x="[X]" y="[Y]" width="30" height="30" as="geometry"/>
</mxCell>
```

Step description text (in legend panel, starting at y=260 from legend border):
```xml
<mxCell id="step-1-label" value="[Step description text]" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;strokeWidth=3;fontColor=#01426A;spacing=0;spacingTop=-7;fontSize=13;" parent="1" vertex="1">
  <mxGeometry x="-110" y="[Y]" width="352" height="30" as="geometry"/>
</mxCell>
```

### Component Styles — Dark Mode Safe

All component styles use **medium-dark fills with white/light text** so diagrams are readable in both draw.io light and dark mode. The key principle: text readability depends on contrast with its fill, not the canvas background.

**Azure internal component** (medium blue fill, white text):
```xml
style="rounded=1;whiteSpace=wrap;html=1;fillColor=#1565C0;strokeColor=#0D47A1;strokeWidth=2;fontSize=10;verticalAlign=middle;fontColor=#FFFFFF;align=left;spacingLeft=40;"
```

**3rd-Party/External system** (amber fill, white text, dashed):
```xml
style="rounded=1;whiteSpace=wrap;html=1;fontSize=10;strokeColor=#E65100;strokeWidth=2;fillColor=#F57F17;dashed=1;dashPattern=1 1;verticalAlign=middle;fontColor=#FFFFFF;align=left;spacingLeft=38;"
```

**Connected System** (orange fill, white text):
```xml
style="rounded=1;whiteSpace=wrap;html=1;fillColor=#EF6C00;strokeColor=#BF360C;strokeWidth=2;fontSize=10;verticalAlign=middle;fontColor=#FFFFFF;align=left;spacingLeft=38;"
```

**Public IP / Network utility** (purple fill, white text):
```xml
style="rounded=1;whiteSpace=wrap;html=1;fillColor=#6A1B9A;strokeColor=#4A148C;strokeWidth=2;fontSize=9;verticalAlign=middle;fontColor=#FFFFFF;"
```

**Environment/region boundary** (dark green, semi-transparent, light green text):
```xml
style="rounded=1;whiteSpace=wrap;html=1;fontSize=14;arcSize=5;fillColor=#1B5E20;strokeColor=#2E7D32;strokeWidth=2;verticalAlign=top;spacingTop=2;fontColor=#C8E6C9;opacity=30;"
```

**VNet boundary** (blue outline, blue text, no fill):
```xml
style="rounded=1;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#42A5F5;fontSize=10;verticalAlign=top;strokeWidth=2;spacingTop=2;fontColor=#64B5F6;"
```

**Subnet boundary** (dark fill, dashed, light gray text):
```xml
style="rounded=1;whiteSpace=wrap;html=1;fillColor=#263238;strokeColor=#455A64;fontSize=9;verticalAlign=middle;dashed=1;fontColor=#B0BEC5;opacity=60;"
```

**CDE System boundary** (red crosshatch outline — use same crosshatch technique as legend):
```xml
style="rounded=1;whiteSpace=wrap;html=1;fontSize=12;strokeWidth=2;fillColor=none;"
<!-- plus two crossing red edge cells like leg-cde-border-1/2 -->
```

**CDE server rack** (pink): `style="verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=#b85450;fillColor=#f8cecc;shape=mxgraph.azure.server_rack;"`

**Connected System server rack** (orange): `style="verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=#d79b00;fillColor=#ffe6cc;shape=mxgraph.azure.server_rack;"`

**Out of Scope server rack** (purple): `style="verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=#9673a6;fillColor=#e1d5e7;shape=mxgraph.azure.server_rack;"`

**Actor/User** (match server color): `style="shape=actor;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;"` (change colors for connected=#ffe6cc/#d79b00, oos=#e1d5e7/#9673a6)

### Azure Icons

Add Azure stencil icons inside component boxes for visual identification. Place icons as **child cells** of the component box (using `parent="<box-id>"`) so they move with the box. Use `fillColor=#FFFFFF` (white) for the icon — white icons are visible against dark fills in both light and dark mode.

**Pattern** — icon as child of a component box:
```xml
<!-- Component box with spacingLeft to make room for icon -->
<mxCell id="my-component" value="&lt;b&gt;Component Name&lt;/b&gt;&lt;br&gt;..."
  style="rounded=1;...;align=left;spacingLeft=40;" parent="1" vertex="1">
  <mxGeometry x="-1200" y="200" width="280" height="65" as="geometry"/>
</mxCell>
<!-- Icon as child (coords relative to parent box) -->
<mxCell id="my-component-icon" value=""
  style="verticalLabelPosition=middle;html=1;verticalAlign=middle;align=center;strokeColor=none;fillColor=#FFFFFF;shape=mxgraph.azure.xxx;pointerEvents=1;"
  parent="my-component" vertex="1">
  <mxGeometry x="8" y="17" width="28" height="28" as="geometry"/>
</mxCell>
```

**Available stencil shapes** — two stencil libraries exist. Use the correct prefix:

**`mxgraph.azure.*`** (legacy Azure stencils — `stencils/azure.xml`):
- `virtual_machine` — VM / VM Scale Set
- `load_balancer_generic` — Load Balancer
- `cloud` — Cloud / SaaS service
- `virtual_network` — Virtual Network
- `server_rack` — Generic server

**`mxgraph.mscae.cloud.*`** (Microsoft Cloud & AI stencils — `stencils/mscae/cloud.xml`):
- `api_management` — API Management
- `application_gateway` — Application Gateway
- `key_vault` — Key Vault
- `gateway` — NAT Gateway / VPN Gateway
- `azure_storage` — Storage Account
- `vm_scale_set` — VM Scale Set
- `nsg` — Network Security Group
- `azure_dns` — Azure DNS
- `vpn_gateway` — VPN Gateway
- `cosmos_db` — Cosmos DB
- `functions` — Azure Functions
- `service_bus` — Service Bus

**IMPORTANT:** Do NOT mix up the prefixes. Shapes only render if they match the correct stencil library. If an icon appears as a blank box, the shape name or prefix is wrong.
- `sql_database_sql_azure` — SQL Database
- `active_directory` — Active Directory / Entra ID

### Arrow/Connection Styles — Dark Mode Safe

Use colored strokes and matching `fontColor` with `labelBackgroundColor=none` on all edge labels. These medium-bright colors are visible against both light and dark canvas backgrounds.

**Internal traffic (blue)**: `style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#42A5F5;strokeWidth=2;endArrow=openThin;endFill=0;fontSize=9;fontColor=#42A5F5;labelBackgroundColor=none;"`

**Outbound/encrypted traffic (green)**: `style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#66BB6A;strokeWidth=2;endArrow=openThin;endFill=0;fontSize=9;fontColor=#66BB6A;labelBackgroundColor=none;"`

**Secret/config retrieval (orange dashed)**: `style="endArrow=oval;html=1;rounded=0;endFill=0;strokeWidth=1;strokeColor=#FFA726;dashed=1;fontSize=8;fontColor=#FFA726;labelBackgroundColor=none;"`

**Utility connection (purple)**: `style="endArrow=openThin;html=1;rounded=0;endFill=0;strokeWidth=1;strokeColor=#CE93D8;"`

**Unencrypted data (red dashed)**: `style="endArrow=classicThin;html=1;rounded=0;endFill=1;strokeWidth=2;fillColor=#f26135;strokeColor=#EF5350;dashed=1;dashPattern=1 2;fontSize=9;fontColor=#EF5350;labelBackgroundColor=none;"`

**Comment indicator (dashed oval-end)**: `style="endArrow=oval;html=1;rounded=0;dashed=1;strokeColor=#78909C;strokeWidth=1;endFill=0;endSize=8;"`

## Step 3 — Export to Editable PNG

The final PNG **must** be an editable bitmap — a PNG with the full draw.io XML embedded so it can be dragged back into draw.io and edited.

### Primary method: draw.io desktop CLI `--embed-diagram` (preferred — produces valid editable PNGs)

```bash
/Applications/draw.io.app/Contents/MacOS/draw.io --export --format png --embed-diagram --scale 2 --output docs/diagrams/<application-name>.png docs/diagrams/<application-name>.drawio
```

This uses draw.io's native export which correctly embeds the XML into the PNG. The `--embed-diagram` flag is the key — it makes the PNG reopenable in draw.io.

### Fallback method: cli-anything-drawio + embed_xml.js

Use this only if the draw.io desktop app is not installed:

```bash
# 1. Render raw PNG
CLI="/opt/homebrew/bin/cli-anything-drawio"
$CLI --json --project docs/diagrams/<application-name>.drawio export render /tmp/diagram-raw.png -f png --crop --overwrite

# 2. Embed XML into the PNG
DRAWIO_SCRIPTS="$HOME/.dotfiles/claude/drawio-scripts"
ls "$DRAWIO_SCRIPTS/node_modules" 2>/dev/null || (cd "$DRAWIO_SCRIPTS" && npm install)
node "$DRAWIO_SCRIPTS/embed_xml.js" /tmp/diagram-raw.png docs/diagrams/<application-name>.drawio docs/diagrams/<application-name>.png
```

### Last resort: Playwright MCP rendering

Use this if neither draw.io desktop nor cli-anything-drawio are available:

```bash
DRAWIO_SCRIPTS="$HOME/.dotfiles/claude/drawio-scripts"
ls "$DRAWIO_SCRIPTS/node_modules" 2>/dev/null || (cd "$DRAWIO_SCRIPTS" && npm install)
node "$DRAWIO_SCRIPTS/render_drawio_html.js" docs/diagrams/<application-name>.drawio /tmp/diagram.html 0
```

Then use the Playwright MCP server to screenshot the HTML, and run `embed_xml.js` to embed the XML.

## Step 4 — Present the File

The final editable PNG must be saved to `docs/diagrams/` in the project repository:

```
docs/diagrams/<application-name>.png
```

Create the `docs/diagrams/` directory if it does not exist. Use the application name (lowercase, hyphenated) as the filename. **Do not save a separate `.drawio` file** — the editable PNG contains the full draw.io XML embedded, so it serves as both the image and the editable source. Users can drag the PNG into draw.io to edit.

The `.drawio` file used during the build process (`docs/diagrams/<application-name>.drawio`) should be removed after the PNG is exported — only the editable PNG is committed to the repository.

## Important Rules

1. **Date format**: Last Reviewed Date MUST be full `YYYY-MM-DD` — never abbreviate
2. **Title font size**: 40px (not 30px) to match real template
3. **CONFIDENTIAL font size**: 40px (not 29px) to match real template
4. **All 4 corners** must be present for proper print margins
5. **Legend**: Copy ALL legend cells verbatim — do not omit any items
6. **GitHub source link**: REQUIRED at x=-1540, y=890 as a `UserObject` with `link` attribute
7. **Coordinate system**: Diagram content uses NEGATIVE x (around -1500 to -250); legend uses x=-200 to 160
8. **HTML entities**: use `&lt;` for `<`, `&gt;` for `>`, `&amp;` for `&` in label values
9. **Cell IDs**: must be unique strings within a diagram
10. **No Version field**: The real metadata block does NOT include Version — omit it
11. **Step circles**: use `strokeWidth=3;fontColor=#01426A` style (not strokeWidth=2)
12. **Editable PNG**: ALWAYS use `draw.io --export --embed-diagram` (preferred) or `embed_xml.js` as fallback — never deliver a plain PNG without embedded XML
13. **Dark mode**: ALWAYS use dark-mode-safe colors — medium-dark fills with white/light text on all components. Never use light fills (#dae8fc, #f5f5f5) with black text — these break in dark mode. Text readability must depend on contrast with its fill, not the canvas background.
14. **Azure icons**: Add stencil icons (white, `fillColor=#FFFFFF`) as child cells inside component boxes. Use the correct stencil prefix: `mxgraph.azure.*` for legacy shapes (virtual_machine, cloud, server_rack, load_balancer_generic, virtual_network) and `mxgraph.mscae.cloud.*` for newer shapes (api_management, application_gateway, key_vault, gateway, nsg, vm_scale_set). Wrong prefix = blank icon. Use `spacingLeft=40` on the parent box to make room.

$ARGUMENTS
