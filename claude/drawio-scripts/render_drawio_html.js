/**
 * render_drawio_html.js — Draw.io XML → HTML preview file
 * Parses .drawio XML using mxGraph/JSDOM and outputs a self-contained HTML file
 * that can be screenshotted by any browser (e.g. Playwright MCP).
 *
 * Usage: node render_drawio_html.js <input.drawio> <output.html> [pageIndex]
 */
'use strict';

const fs   = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');
const MXGRAPH_JS = path.resolve(__dirname, 'node_modules/mxgraph/javascript/mxClient.js');

// ─── 1. Parse drawio XML → cell list ──────────────────────────────────────

async function parseDiagram(xml, pageIndex = 0) {
  if (!fs.existsSync(MXGRAPH_JS)) throw new Error('Run: npm install in scripts/');
  const dom = new JSDOM('<!DOCTYPE html><html><body><div id="c"></div></body></html>', {
    runScripts: 'dangerously', pretendToBeVisual: true,
  });
  const { window: win } = dom;
  const s = win.document.createElement('script');
  s.textContent = fs.readFileSync(MXGRAPH_JS, 'utf8');
  win.document.head.appendChild(s);
  await new Promise(r => setTimeout(r, 400));

  const parser   = new win.DOMParser();
  const mxDoc    = parser.parseFromString(xml, 'text/xml');
  const diagrams = Array.from(mxDoc.getElementsByTagName('diagram'));
  if (!diagrams.length) throw new Error('No <diagram> found');

  const diagram     = diagrams[Math.min(pageIndex, diagrams.length - 1)];
  const diagramName = diagram.getAttribute('name') || 'Diagram';
  const totalPages  = diagrams.length;

  let gmEl = diagram.querySelector('mxGraphModel');
  if (!gmEl) gmEl = parser.parseFromString(diagram.textContent.trim(), 'text/xml').documentElement;

  const container = win.document.getElementById('c');
  const graph     = new win.mxGraph(container);
  graph.setEnabled(false);
  graph.setHtmlLabels(false);
  new win.mxCodec(gmEl.ownerDocument).decode(gmEl, graph.getModel());

  const model = graph.getModel();
  const cells = [];
  const cellMap = {};

  function collectCells(cell) {
    if (!cell) return;
    const geo   = cell.geometry;
    const style = cell.style || '';
    let label   = '';
    const val   = cell.value;
    if (typeof val === 'string') label = val;
    else if (val && val.getAttribute) label = val.getAttribute('label') || val.textContent || '';
    const link = (val && val.getAttribute) ? val.getAttribute('link') : null;
    label = label.replace(/<[^>]+>/g,'').replace(/&amp;/g,'&').replace(/&lt;/g,'<')
                 .replace(/&gt;/g,'>').replace(/&nbsp;/g,' ').replace(/\s+/g,' ').trim();

    if (cell.id !== '0' && cell.id !== '1') {
      const c = {
        id: cell.id, label, link, style,
        x: geo ? (geo.x || 0) : 0, y: geo ? (geo.y || 0) : 0,
        w: geo ? (geo.width  || 0) : 0, h: geo ? (geo.height || 0) : 0,
        isEdge: cell.isEdge() || false,
        source: cell.source ? cell.source.id : null,
        target: cell.target ? cell.target.id : null,
        parent: cell.parent ? cell.parent.id : '1',
      };
      cells.push(c);
      cellMap[c.id] = c;
    }
    for (const child of model.getChildCells(cell)) collectCells(child);
  }
  collectCells(model.getCell('1'));

  function absPos(cell) {
    if (!cell) return { x:0, y:0 };
    if (cell.parent === '1' || !cell.parent) return { x: cell.x, y: cell.y };
    const p = cellMap[cell.parent];
    if (!p) return { x: cell.x, y: cell.y };
    const po = absPos(p);
    return { x: cell.x + po.x, y: cell.y + po.y };
  }
  for (const c of cells) {
    const abs = absPos(c);
    c.ax = abs.x; c.ay = abs.y;
  }

  const verts = cells.filter(c => !c.isEdge && c.w > 0);
  const xs = verts.map(c => c.ax), ys = verts.map(c => c.ay);
  const xe = verts.map(c => c.ax + c.w), ye = verts.map(c => c.ay + c.h);

  return {
    cells, cellMap,
    minX: Math.min(...xs), minY: Math.min(...ys),
    maxX: Math.max(...xe), maxY: Math.max(...ye),
    diagramName, totalPages,
  };
}

// ─── 2. Classify cells ────────────────────────────────────────────────────

function parseStyle(s) {
  const r = {};
  (s || '').split(';').forEach(p => {
    const i = p.indexOf('=');
    if (i > 0) r[p.slice(0,i).trim()] = p.slice(i+1).trim();
  });
  return r;
}

function classify(c) {
  const s = c.style || '';
  const st = parseStyle(s);
  if (c.isEdge)                                         return 'edge';
  if (s.includes('shape=actor'))                        return 'actor';
  if (s.includes('fillColor=#c0f7ff') && s.includes('ellipse')) return 'badge';
  if (s.includes('7A1D2F') && st.fontSize === '40')     return 'watermark';
  if (st.fontSize === '40')                             return 'title';
  if (st.fontSize === '14' && s.includes('strokeColor=none') && !s.includes('01426A')) return 'metadata';
  if (s.includes('01426A') && st.fontSize === '13')     return 'step-desc';
  if (s.includes('01426A'))                             return 'step-desc';
  if ((s.includes('4D6366') || s.includes('fontSize=10')) && s.includes('strokeColor=none') && !s.includes('fillColor=')) return 'legend-text';
  if (!s.includes('shape=') && c.w > 100 && c.h > 80)  return 'zone';
  if (s.includes('shape=mxgraph') || s.includes('shape=mscae')) return 'icon';
  if (c.w > 0 && !s.includes('shape=') && c.w < 80 && c.h < 80) return 'small-box';
  return 'box';
}

// ─── 3. Icon SVG library ──────────────────────────────────────────────────

function iconSvg(shapeStr, fill, stroke) {
  const f = fill  || '#e3f2fd';
  const s = stroke|| '#1565c0';
  const sh = shapeStr || '';

  if (sh.includes('gateway') || sh.includes('apim')) return `
    <svg viewBox="0 0 36 36" width="36" height="36" fill="none">
      <rect x="3" y="8" width="30" height="20" rx="4" fill="${f}" fill-opacity="0.7" stroke="${s}" stroke-width="2"/>
      <circle cx="10" cy="18" r="3" fill="${s}" opacity="0.8"/>
      <circle cx="18" cy="18" r="3" fill="${s}" opacity="0.8"/>
      <circle cx="26" cy="18" r="3" fill="${s}" opacity="0.8"/>
      <line x1="3" y1="14" x2="33" y2="14" stroke="${s}" stroke-width="1.2" opacity="0.35"/>
      <line x1="3" y1="22" x2="33" y2="22" stroke="${s}" stroke-width="1.2" opacity="0.35"/>
    </svg>`;

  if (sh.includes('azure_website') || sh.includes('app_generic')) return `
    <svg viewBox="0 0 36 36" width="36" height="36" fill="none">
      <rect x="2" y="7" width="32" height="22" rx="3" fill="${f}" fill-opacity="0.7" stroke="${s}" stroke-width="2"/>
      <line x1="2" y1="13" x2="34" y2="13" stroke="${s}" stroke-width="1.5"/>
      <circle cx="7" cy="10" r="1.5" fill="${s}"/>
      <circle cx="12" cy="10" r="1.5" fill="${s}"/>
      <rect x="6" y="17" width="24" height="7" rx="1.5" fill="${s}" opacity="0.2"/>
      <line x1="6" y1="27" x2="30" y2="27" stroke="${s}" stroke-width="1.2" opacity="0.4"/>
    </svg>`;

  if (sh.includes('load_balancer') || sh.includes('cisco_safe') || sh.includes('front')) return `
    <svg viewBox="0 0 36 36" width="36" height="36" fill="none">
      <path d="M18,4 L32,12 L32,28 L4,28 L4,12 Z" fill="${f}" fill-opacity="0.7" stroke="${s}" stroke-width="2"/>
      <rect x="13" y="20" width="10" height="8" rx="1.5" fill="${s}" opacity="0.45"/>
      <circle cx="18" cy="12" r="2.5" fill="${s}" opacity="0.8"/>
    </svg>`;

  if (sh.includes('log_management') || sh.includes('oms')) return `
    <svg viewBox="0 0 36 36" width="36" height="36" fill="none">
      <rect x="3" y="3" width="30" height="30" rx="4" fill="${f}" fill-opacity="0.7" stroke="${s}" stroke-width="2"/>
      <path d="M8,26 L12,17 L16.5,22 L21,11 L25,17 L29,14" stroke="${s}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    </svg>`;

  if (sh.includes('server_rack') || sh.includes('server')) return `
    <svg viewBox="0 0 36 36" width="36" height="36" fill="none">
      <rect x="3" y="5" width="30" height="26" rx="3" fill="${f}" fill-opacity="0.7" stroke="${s}" stroke-width="2"/>
      <rect x="6" y="8" width="24" height="5" rx="1.5" fill="${s}" opacity="0.25"/>
      <rect x="6" y="15.5" width="24" height="5" rx="1.5" fill="${s}" opacity="0.25"/>
      <rect x="6" y="23" width="24" height="3.5" rx="1.5" fill="${s}" opacity="0.15"/>
      <circle cx="27" cy="10.5" r="1.5" fill="${s}" opacity="0.8"/>
      <circle cx="27" cy="18" r="1.5" fill="${s}" opacity="0.8"/>
    </svg>`;

  return `
    <svg viewBox="0 0 36 36" width="36" height="36" fill="none">
      <rect x="3" y="3" width="30" height="30" rx="5" fill="${f}" fill-opacity="0.6" stroke="${s}" stroke-width="2"/>
      <circle cx="18" cy="18" r="6" fill="${s}" opacity="0.2"/>
      <circle cx="18" cy="18" r="3" fill="${s}" opacity="0.5"/>
    </svg>`;
}

// ─── 4. Color helpers ─────────────────────────────────────────────────────

function hexToRgb(hex) {
  if (!hex || !hex.startsWith('#')) return null;
  const n = parseInt(hex.replace('#',''), 16);
  if (isNaN(n)) return null;
  return { r:(n>>16)&255, g:(n>>8)&255, b:n&255 };
}
function lightenHex(hex, amt=40) {
  if (!hex || !hex.startsWith('#')) return hex||'#f5f5f5';
  const n = parseInt(hex.slice(1),16);
  const r = Math.min(255,((n>>16)&255)+amt);
  const g = Math.min(255,((n>>8)&255)+amt);
  const b = Math.min(255,(n&255)+amt);
  return `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
}

// ─── 5. Build HTML ────────────────────────────────────────────────────────

function buildHtml({ cells, cellMap, minX, minY, maxX, maxY, diagramName }) {
  const PAD    = 52;
  const SCALE  = 1.0;
  const PANEL  = 380;
  const PGAP   = 32;

  const diagW  = Math.ceil((maxX - minX) * SCALE) + PAD * 2;
  const diagH  = Math.ceil((maxY - minY) * SCALE) + PAD * 2;
  const totalW = diagW + PGAP + PANEL;
  const totalH = Math.max(diagH, 760);

  function tx(x) { return Math.round((x - minX) * SCALE + PAD); }
  function ty(y) { return Math.round((y - minY) * SCALE + PAD); }
  function tw(w) { return Math.round(w * SCALE); }
  function th(h) { return Math.round(h * SCALE); }

  const zones    = cells.filter(c => classify(c) === 'zone').sort((a,b) => (b.w*b.h)-(a.w*a.h));
  const edges    = cells.filter(c => c.isEdge);
  const actors   = cells.filter(c => classify(c) === 'actor');
  const icons    = cells.filter(c => classify(c) === 'icon');
  const badges   = cells.filter(c => classify(c) === 'badge');
  const stepDescs= cells.filter(c => classify(c) === 'step-desc' && c.w > 100).sort((a,b)=>a.ay-b.ay);
  const titleCell= cells.find(c => classify(c) === 'title');
  const metaCell = cells.find(c => classify(c) === 'metadata');
  const srcCell  = cells.find(c => c.link && c.link.includes('github'));
  const githubUrl = srcCell ? srcCell.link : '';

  const titleText = titleCell ? titleCell.label : diagramName;
  const metaLines = metaCell
    ? metaCell.label.split(/\n|<br>/).map(l => {
        const i = l.indexOf(':');
        return i>0 ? `<b>${l.slice(0,i+1)}</b>${l.slice(i+1)}` : l;
      }).join('<br>')
    : '';

  let svgZones = '';
  zones.forEach(z => {
    const st = parseStyle(z.style);
    const fill   = st.fillColor  || '#f5f5f5';
    const stroke = st.strokeColor|| '#999';
    const isDash = z.style.includes('dashed=1');
    const opacity= Math.min(parseFloat(st.opacity||'100')/100, 0.28);
    const rgb    = hexToRgb(fill);
    const fillCss= rgb ? `rgba(${rgb.r},${rgb.g},${rgb.b},${opacity})` : fill;
    const arcSize= parseFloat(st.arcSize||'7')/100;
    const rx     = Math.round(arcSize * Math.min(tw(z.w), th(z.h)) / 2 * 2);
    const dashAttr= isDash ? 'stroke-dasharray="7,4"' : '';
    const sw     = isDash ? '1.5' : '2';
    const labelClean = z.label.replace(/<[^>]+>/g,'').replace(/&amp;/g,'&').trim();
    svgZones += `
      <rect x="${tx(z.ax)}" y="${ty(z.ay)}" width="${tw(z.w)}" height="${th(z.h)}"
            rx="${rx}" fill="${fillCss}" stroke="${stroke}" stroke-width="${sw}" ${dashAttr}/>
      ${labelClean ? `<text x="${tx(z.ax)+14}" y="${ty(z.ay)+18}"
            font-family="'Segoe UI',Arial,sans-serif" font-size="12.5" font-weight="700"
            fill="${stroke}">${labelClean.replace(/</g,'&lt;').slice(0,60)}</text>` : ''}`;
  });

  const arrowColors = new Set(['5b8ec2','82b366','b85450','9673a6','888888','6c8ebf']);
  edges.forEach(e => {
    const sc = (parseStyle(e.style).strokeColor || '#6c8ebf').replace('#','').toLowerCase();
    arrowColors.add(sc);
  });
  let defs = '<defs>';
  arrowColors.forEach(c => {
    defs += `<marker id="ah-${c}" markerWidth="9" markerHeight="7" refX="8" refY="3.5" orient="auto">
      <path d="M0,1 L0,6 L8,3.5 Z" fill="#${c}"/></marker>`;
  });
  defs += '</defs>';

  let svgEdges = '';
  edges.forEach(e => {
    const src = e.source ? cellMap[e.source] : null;
    const tgt = e.target ? cellMap[e.target] : null;
    if (!src || !tgt) return;
    const cx1 = tx(src.ax + src.w/2);
    const cy1 = ty(src.ay + src.h/2);
    const cx2 = tx(tgt.ax + tgt.w/2);
    const cy2 = ty(tgt.ay + tgt.h/2);
    const st   = parseStyle(e.style);
    const sc   = (st.strokeColor || '#6c8ebf').replace('#','').toLowerCase();
    const sw   = st.strokeWidth || '2.2';
    const dash = e.style.includes('dashed=1') ? 'stroke-dasharray="6,4"' : '';
    const marker = `marker-end="url(#ah-${sc})"`;
    const mx = (cx1 + cx2) / 2;
    svgEdges += `<path d="M${cx1},${cy1} C${mx},${cy1} ${mx},${cy2} ${cx2},${cy2}"
      stroke="#${sc}" stroke-width="${sw}" fill="none" ${dash} ${marker} stroke-linecap="round"/>`;
  });

  let iconHtml = '';
  icons.forEach(ic => {
    const st     = parseStyle(ic.style);
    const fill   = st.fillColor  || '#e3f2fd';
    const stroke = st.strokeColor|| '#1565c0';
    const shape  = st.shape      || '';
    const grad   = `linear-gradient(145deg,${lightenHex(fill,35)},${fill})`;
    const SIZE   = 62;
    const cx     = tx(ic.ax + ic.w/2) - SIZE/2;
    const cy     = ty(ic.ay + ic.h/2) - SIZE/2;
    iconHtml += `
    <div style="position:absolute;left:${cx}px;top:${cy - 4}px;
                display:flex;flex-direction:column;align-items:center;gap:5px;text-align:center;">
      <div style="width:${SIZE}px;height:${SIZE}px;background:${grad};border:2px solid ${stroke};
                  border-radius:14px;box-shadow:0 3px 10px rgba(0,0,0,0.16),0 1px 4px rgba(0,0,0,0.1);
                  display:flex;align-items:center;justify-content:center;">
        ${iconSvg(shape, fill, stroke)}
      </div>
      ${ic.label ? `<div style="font-size:11px;font-weight:700;color:#111;max-width:106px;
                                line-height:1.3;font-family:'Segoe UI',Arial,sans-serif;">${ic.label}</div>` : ''}
    </div>`;
  });

  let actorHtml = '';
  actors.forEach(a => {
    const st     = parseStyle(a.style);
    const fill   = st.fillColor  || '#f8cecc';
    const stroke = st.strokeColor|| '#b85450';
    const grad   = `linear-gradient(145deg,${lightenHex(fill,30)},${fill})`;
    const SIZE   = 52;
    const cx     = tx(a.ax + a.w/2) - SIZE/2;
    const cy     = ty(a.ay);
    actorHtml += `
    <div style="position:absolute;left:${cx}px;top:${cy}px;
                display:flex;flex-direction:column;align-items:center;gap:5px;text-align:center;">
      <div style="width:${SIZE}px;height:${SIZE}px;background:${grad};border:2px solid ${stroke};
                  border-radius:12px;box-shadow:0 3px 10px rgba(0,0,0,0.15);
                  display:flex;align-items:center;justify-content:center;">
        <svg viewBox="0 0 28 28" width="30" height="30" fill="none">
          <circle cx="14" cy="9" r="5" fill="${stroke}" opacity="0.85"/>
          <path d="M4,25 Q4,17 14,17 Q24,17 24,25" stroke="${stroke}" stroke-width="2.5" fill="none" stroke-linecap="round"/>
        </svg>
      </div>
      ${a.label ? `<div style="font-size:10.5px;font-weight:700;color:${stroke};max-width:92px;
                               line-height:1.3;font-family:'Segoe UI',Arial,sans-serif;">${a.label}</div>` : ''}
    </div>`;
  });

  let badgeHtml = '';
  badges.forEach(b => {
    badgeHtml += `
    <div style="position:absolute;left:${tx(b.ax)}px;top:${ty(b.ay)}px;
                width:${Math.max(tw(b.w),24)}px;height:${Math.max(th(b.h),24)}px;
                border-radius:50%;background:#c0f7ff;border:2.5px solid #00cff0;
                display:flex;align-items:center;justify-content:center;
                font-size:10.5px;font-weight:800;color:#01426A;
                font-family:'Segoe UI',Arial,sans-serif;
                box-shadow:0 1px 5px rgba(0,200,240,0.35);z-index:20;">
      ${b.label}
    </div>`;
  });

  const flowHtml = stepDescs.map((s,i) => `
    <div style="display:flex;gap:10px;margin-bottom:10px;align-items:flex-start;">
      <div style="width:22px;height:22px;border-radius:50%;background:#c0f7ff;border:2.5px solid #00cff0;
           display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:800;
           color:#01426A;flex-shrink:0;font-family:'Segoe UI',Arial,sans-serif;">${i+1}</div>
      <div style="font-size:10.5px;color:#01426A;line-height:1.5;font-family:'Segoe UI',Arial,sans-serif;">${s.label}</div>
    </div>`).join('');

  const SH = `font-size:9px;font-weight:800;color:#bbb;text-transform:uppercase;letter-spacing:1.3px;
              border-bottom:1.5px solid #ececec;padding-bottom:5px;margin-bottom:10px;margin-top:16px;
              font-family:'Segoe UI',Arial,sans-serif;`;
  const LR = `display:flex;align-items:center;gap:8px;margin-bottom:7px;`;
  const LT = `font-size:10px;color:#4a5568;font-family:'Segoe UI',Arial,sans-serif;`;

  const panel = `
  <div style="position:absolute;left:${diagW + PGAP}px;top:30px;width:${PANEL - 20}px;">
    <div style="font-size:22px;font-weight:800;color:#0d0d0d;line-height:1.25;margin-bottom:14px;
                font-family:'Segoe UI',Arial,sans-serif;letter-spacing:-0.3px;">${titleText}</div>
    <div style="font-size:11px;color:#555;line-height:1.9;margin-bottom:4px;
                font-family:'Segoe UI',Arial,sans-serif;">${metaLines}</div>

    <div style="${SH}">Zones</div>
    <div style="${LR}">
      <div style="width:32px;height:10px;border-radius:3px;flex-shrink:0;
                  background:rgba(192,229,133,0.35);border:1.5px solid #5E8741;"></div>
      <span style="${LT}">Azure Environment</span>
    </div>
    <div style="${LR}">
      <div style="width:32px;height:10px;border-radius:3px;flex-shrink:0;
                  background:rgba(255,219,103,0.35);border:1.5px dashed #e5ad07;"></div>
      <span style="${LT}">3rd-Party / External System</span>
    </div>
    <div style="${LR}">
      <div style="width:32px;height:10px;border-radius:3px;flex-shrink:0;
                  background:rgba(235,235,235,0.6);border:1.5px dashed #bbb;"></div>
      <span style="${LT}">Internal Grouping</span>
    </div>
    <div style="${LR}">
      <div style="width:32px;height:10px;border-radius:3px;flex-shrink:0;
                  background:none;border:2px solid #e53935;"></div>
      <span style="${LT}">CDE Boundary (Logical Grouping)</span>
    </div>

    <div style="${SH}">Connections</div>
    <div style="${LR}">
      <svg width="36" height="13" style="flex-shrink:0"><line x1="1" y1="6.5" x2="27" y2="6.5" stroke="#5b8ec2" stroke-width="2.5"/><polygon points="25,3.5 33,6.5 25,9.5" fill="#5b8ec2"/></svg>
      <span style="${LT}">Encrypted HTTPS (TLS 1.2, Port 443)</span>
    </div>
    <div style="${LR}">
      <svg width="36" height="13" style="flex-shrink:0"><line x1="1" y1="6.5" x2="27" y2="6.5" stroke="#82b366" stroke-width="2.5"/><polygon points="25,3.5 33,6.5 25,9.5" fill="#82b366"/></svg>
      <span style="${LT}">Encrypted Other</span>
    </div>
    <div style="${LR}">
      <svg width="36" height="13" style="flex-shrink:0"><line x1="1" y1="6.5" x2="27" y2="6.5" stroke="#5b8ec2" stroke-width="2" stroke-dasharray="5,3"/><polygon points="25,3.5 33,6.5 25,9.5" fill="#5b8ec2" opacity="0.6"/></svg>
      <span style="${LT}">App logging / metrics</span>
    </div>
    <div style="${LR}">
      <svg width="36" height="13" style="flex-shrink:0"><line x1="1" y1="6.5" x2="25" y2="6.5" stroke="#aaa" stroke-width="1.5" stroke-dasharray="3,2"/><circle cx="30" cy="6.5" r="3.5" fill="none" stroke="#aaa" stroke-width="1.5"/></svg>
      <span style="${LT}">Comment indicator</span>
    </div>

    <div style="${SH}">System Types</div>
    <div style="${LR}">
      <div style="width:11px;height:16px;border-radius:3px;flex-shrink:0;background:linear-gradient(145deg,#fdecea,#ffcdd2);border:1.5px solid #ef9a9a;"></div>
      <div style="width:13px;height:13px;border-radius:3px;flex-shrink:0;background:linear-gradient(145deg,#fdecea,#ffcdd2);border:1.5px solid #ef9a9a;"></div>
      <span style="${LT}">CDE Systems</span>
    </div>
    <div style="${LR}">
      <div style="width:11px;height:16px;border-radius:3px;flex-shrink:0;background:linear-gradient(145deg,#fff8e1,#ffe0b2);border:1.5px solid #ffb74d;"></div>
      <div style="width:13px;height:13px;border-radius:3px;flex-shrink:0;background:linear-gradient(145deg,#fff8e1,#ffe0b2);border:1.5px solid #ffb74d;"></div>
      <span style="${LT}">Connected System</span>
    </div>
    <div style="${LR}">
      <div style="width:11px;height:16px;border-radius:3px;flex-shrink:0;background:linear-gradient(145deg,#ede7f6,#d1c4e9);border:1.5px solid #ce93d8;"></div>
      <div style="width:13px;height:13px;border-radius:3px;flex-shrink:0;background:linear-gradient(145deg,#ede7f6,#d1c4e9);border:1.5px solid #ce93d8;"></div>
      <span style="${LT}">Out of Scope System</span>
    </div>
    <div style="${LR}">
      <div style="width:11px;height:16px;border-radius:3px;flex-shrink:0;background:#f5f5f5;border:1.5px solid #bbb;"></div>
      <div style="width:13px;height:13px;border-radius:3px;flex-shrink:0;background:#f5f5f5;border:1.5px solid #bbb;"></div>
      <span style="${LT}">Other Internal System</span>
    </div>

    ${flowHtml ? `<div style="${SH}">Flow Steps</div>${flowHtml}` : ''}
  </div>`;

  const corners = `
    <polyline points="${PAD-10},${PAD} ${PAD},${PAD} ${PAD},${PAD-10}" fill="none" stroke="#d0d0d0" stroke-width="1.8"/>
    <polyline points="${diagW-PAD},${PAD-10} ${diagW-PAD},${PAD} ${diagW-PAD+10},${PAD}" fill="none" stroke="#d0d0d0" stroke-width="1.8"/>
    <polyline points="${PAD-10},${totalH-PAD} ${PAD},${totalH-PAD} ${PAD},${totalH-PAD+10}" fill="none" stroke="#d0d0d0" stroke-width="1.8"/>
    <polyline points="${diagW-PAD},${totalH-PAD+10} ${diagW-PAD},${totalH-PAD} ${diagW-PAD+10},${totalH-PAD}" fill="none" stroke="#d0d0d0" stroke-width="1.8"/>`;

  return { html: `<!DOCTYPE html><html><head><meta charset="utf-8">
<style>*{margin:0;padding:0;box-sizing:border-box;}body{background:white;}</style>
</head><body>
<div id="diagram-root" style="position:relative;width:${totalW}px;height:${totalH}px;background:white;overflow:hidden;">

<svg style="position:absolute;top:0;left:0;pointer-events:none;" width="${diagW}" height="${totalH}"
     xmlns="http://www.w3.org/2000/svg">
  ${defs}
  ${svgZones}
  ${svgEdges}
  ${corners}
  <line x1="${diagW + PGAP/2}" y1="50" x2="${diagW + PGAP/2}" y2="${totalH-50}"
        stroke="#e8e8e8" stroke-width="1.5"/>
</svg>

${iconHtml}
${actorHtml}
${badgeHtml}
${panel}

<div style="position:absolute;bottom:28px;left:${PAD}px;font-size:30px;font-weight:900;
     color:rgba(122,29,47,0.55);letter-spacing:5px;font-family:'Segoe UI',Arial,sans-serif;">
  CONFIDENTIAL
</div>
<div style="position:absolute;bottom:9px;left:${PAD}px;font-size:9px;color:#bbb;
     font-family:'Segoe UI',Arial,sans-serif;">
  ${githubUrl ? `Source: ${githubUrl}` : ''}
</div>

</div></body></html>`, totalW, totalH };
}

// ─── 6. Main ──────────────────────────────────────────────────────────────

async function main(inputFile, outputFile, pageIndex) {
  if (!fs.existsSync(inputFile)) throw new Error(`Not found: ${inputFile}`);
  const xml = fs.readFileSync(inputFile, 'utf8');
  console.log(`Parsing: ${path.basename(inputFile)}`);

  const parsed = await parseDiagram(xml, pageIndex);
  console.log(`  Page ${pageIndex+1}/${parsed.totalPages}: "${parsed.diagramName}"`);

  const { html, totalW, totalH } = buildHtml(parsed);

  fs.writeFileSync(outputFile, html, 'utf8');
  console.log(`  HTML saved: ${outputFile} (${totalW}x${totalH}px)`);
  console.log(JSON.stringify({ width: totalW, height: totalH }));
}

const [,,inp,out,pg] = process.argv;
if (!inp || !out) { process.stderr.write('Usage: node render_drawio_html.js <in.drawio> <out.html> [page]\n'); process.exit(1); }
main(inp, out, parseInt(pg||'0',10)).catch(e=>{ console.error(e.message); process.exit(1); });
