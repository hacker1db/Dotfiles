# Draw.io — Component Styles & XML Reference

## Outer Wrapper (Required)

```xml
<mxfile host="Electron" version="27.0.9">
  <diagram id="[UNIQUE_ID]" name="[DIAGRAM_NAME]">
    <mxGraphModel dx="3073" dy="889" grid="1" gridSize="10" guides="1" tooltips="1"
                  connect="1" arrows="1" fold="1" page="0" pageScale="1"
                  pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- all content cells here -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## Mandatory Chrome Elements (Copy Verbatim)

### Corner Print Margin Markers (All 4 Required)

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

### Title (fontSize=40, Required)

```xml
<mxCell id="title" value="[DIAGRAM TITLE]"
  style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=40;fontColor=#000000;opacity=75;"
  parent="1" vertex="1">
  <mxGeometry x="-192" y="80" width="510" height="60" as="geometry"/>
</mxCell>
```

### Metadata Block (No Version field)

```xml
<mxCell id="metadata"
  value="Team Name: [TEAM]&lt;br&gt;SME: [SME]&lt;br&gt;Copyright: Alaska Air Group, Inc [YEAR]&lt;br&gt;Last Reviewed Date: [YYYY-MM-DD]"
  style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=14;fontColor=#000000;opacity=75;"
  parent="1" vertex="1">
  <mxGeometry x="-192" y="140" width="440" height="80" as="geometry"/>
</mxCell>
```

### Legend Border Lines (L-shaped)

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

### CONFIDENTIAL Watermark (fontSize=40, Required)

```xml
<mxCell id="confidential" value="CONFIDENTIAL"
  style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=40;fontColor=#7A1D2F;opacity=75;"
  parent="1" vertex="1">
  <mxGeometry x="-1540" y="840" width="340" height="70" as="geometry"/>
</mxCell>
```

### GitHub Source Link (Required, x=-1540 y=890)

```xml
<UserObject label="&lt;font color=&quot;#666666&quot;&gt;Source: https://github.com/[ORG]/[REPO]/tree/main/diagrams/[FILE].drawio&lt;/font&gt;"
  link="https://github.com/[ORG]/[REPO]/tree/main/diagrams/[FILE].drawio" id="github-source">
  <mxCell style="text;whiteSpace=wrap;html=1;" parent="1" vertex="1">
    <mxGeometry x="-1540" y="890" width="810" height="20" as="geometry"/>
  </mxCell>
</UserObject>
```

---

## Legend Items (All Required, Copy Verbatim)

```xml
<!-- Environment (green) -->
<mxCell id="leg-env-swatch" value="" style="rounded=1;whiteSpace=wrap;html=1;fontSize=12;strokeColor=#5e8741;fillColor=#c0e585;arcSize=5;opacity=33;" parent="1" vertex="1">
  <mxGeometry x="-191.76" y="244" width="40" height="10" as="geometry"/>
</mxCell>
<mxCell id="leg-env-label" value="Environment" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-141.76" y="239" width="140" height="20" as="geometry"/>
</mxCell>

<!-- 3rd-Party/External (yellow dotted) -->
<mxCell id="leg-p2pe-swatch" value="" style="rounded=0;whiteSpace=wrap;html=1;fontSize=10;strokeColor=#e5ad07;strokeWidth=1;fillColor=#ffdb67;opacity=75;dashed=1;dashPattern=1 1;" parent="1" vertex="1">
  <mxGeometry x="-191.76" y="264" width="40" height="10" as="geometry"/>
</mxCell>
<mxCell id="leg-p2pe-label" value="3rd-Party or External System" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#4D6366;" parent="1" vertex="1">
  <mxGeometry x="-142.9" y="259" width="140" height="20" as="geometry"/>
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
```

> See full legend XML (CDE swatch, Connected System, OOS System, comment indicator) in `assets/template/template.drawio`.

---

## Component Styles (Diagram Content Area)

### Environment / Zone Boundary
```
style="rounded=1;whiteSpace=wrap;html=1;fontSize=12;arcSize=7;opacity=33;verticalAlign=top;"
```

### 3rd-Party / External System Box
```
style="rounded=0;whiteSpace=wrap;html=1;fontSize=10;strokeColor=#e5ad07;strokeWidth=1;fillColor=#ffdb67;opacity=75;dashed=1;dashPattern=1 1;verticalAlign=top;"
```

### Server Rack Icons

| Type | fillColor | strokeColor |
|------|-----------|-------------|
| CDE (pink) | `#f8cecc` | `#b85450` |
| Connected System (orange) | `#ffe6cc` | `#d79b00` |
| Out of Scope (purple) | `#e1d5e7` | `#9673a6` |
| Other Internal | default | default |

```
style="verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=[COLOR];fillColor=[COLOR];shape=mxgraph.azure.server_rack;"
```

### Actor / User
```
style="shape=actor;whiteSpace=wrap;html=1;fillColor=[COLOR];strokeColor=[COLOR];"
```

---

## Arrow Styles

| Type | Style snippet |
|------|--------------|
| Encrypted HTTPS (blue) | `endArrow=openThin;strokeColor=#6c8ebf;strokeWidth=2;fillColor=#dae8fc;` |
| Encrypted Other (green) | `endArrow=openThin;strokeColor=#82b366;strokeWidth=2;fillColor=#d5e8d4;` |
| Unencrypted (orange/red dashed) | `endArrow=classicThin;strokeColor=#B82B47;strokeWidth=2;fillColor=#f26135;dashed=1;dashPattern=1 2;` |
| Comment indicator | `endArrow=oval;dashed=1;strokeColor=#404D2C;strokeWidth=1;endFill=0;endSize=8;` |

---

## Flow Step Callouts

```xml
<!-- Numbered circle on diagram -->
<mxCell id="step-1" value="&lt;p style=&quot;line-height: 100%;&quot;&gt;1&lt;/p&gt;"
  style="ellipse;whiteSpace=wrap;html=1;aspect=fixed;spacing=0;spacingLeft=1;fillColor=#c0f7ff;strokeColor=#00cff0;strokeWidth=3;fontColor=#01426A;"
  parent="1" vertex="1">
  <mxGeometry x="[X]" y="[Y]" width="30" height="30" as="geometry"/>
</mxCell>

<!-- Step label in legend panel -->
<mxCell id="step-1-label" value="[Step description]"
  style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;strokeWidth=3;fontColor=#01426A;fontSize=13;"
  parent="1" vertex="1">
  <mxGeometry x="-110" y="[Y]" width="352" height="30" as="geometry"/>
</mxCell>
```
