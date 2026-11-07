import { View, div, image } from "gpui-kit";
import { v_flex, h_flex, Scrollbar, VirtualListScrollHandle, v_virtual_list } from "gpui-base";
import { appHome, exec, nextCommand, props, theme } from "herdr";

const DPI = 144;
const GAP = 16;
const ZOOMS = [0.5, 0.67, 0.8, 1, 1.25, 1.5, 2];

function hash(text) {
  let h = 5381;
  for (let i = 0; i < text.length; i++) h = ((h << 5) + h + text.charCodeAt(i)) >>> 0;
  return h.toString(16);
}

export default class PdfView extends View {
  init(p, cx) {
    this.path = p?.path ?? props()?.path ?? "";
    this.name = this.path.split("/").pop();
    this.pages = [];
    this.ready = new Set();
    this.error = this.path ? null : "No PDF path given";
    this.zoom = 3;
    this.width = 900;
    this.visible = 0;
    this.scroll = VirtualListScrollHandle.new();
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      for (;;) {
        if ((await nextCommand()) === "focus") { this.handle.focus(); cx.notify(); }
      }
    });
    if (this.path) this.load(cx);
  }

  load(cx) {
    cx.spawn(async (cx) => {
      try {
        const stat = await exec("stat", ["-f", "%m", this.path]);
        if (stat.code !== 0) throw new Error(`Cannot read ${this.path}`);
        const info = await exec("pdfinfo", ["-f", "1", "-l", "100000", this.path], { timeout: 60000 });
        if (info.code !== 0) throw new Error(info.stderr.trim() || "pdfinfo failed (is poppler installed?)");
        this.title = /^Title:\s+(.+)$/m.exec(info.stdout)?.[1]?.trim() || null;
        const count = Number(/^Pages:\s+(\d+)/m.exec(info.stdout)?.[1] ?? 0);
        const sizes = {};
        for (const m of info.stdout.matchAll(/^Page\s+(\d+) size:\s+([\d.]+) x ([\d.]+)/gm)) sizes[+m[1]] = [+m[2], +m[3]];
        const fallback = /^Page size:\s+([\d.]+) x ([\d.]+)/m.exec(info.stdout);
        const base = fallback ? [+fallback[1], +fallback[2]] : [612, 792];
        this.pages = Array.from({ length: count }, (_, i) => ({ n: i + 1, size: sizes[i + 1] ?? base }));
        this.key = hash(`${this.path}:${stat.stdout.trim()}`);
        this.dir = `${appHome()}/data/pdf/${this.key}`;
        await exec("mkdir", ["-p", this.dir]);
        const have = await exec("ls", [this.dir]);
        for (const f of have.stdout.split("\n")) { const m = /^p(\d+)\.png$/.exec(f); if (m) this.ready.add(+m[1]); }
        cx.notify();
        this.renderPages(cx);
      } catch (e) {
        this.error = String(e.message ?? e);
        cx.notify();
      }
    });
  }

  renderPages(cx) {
    if (this.rendering) return;
    this.rendering = true;
    cx.spawn(async (cx) => {
      for (;;) {
        const near = this.pages.map((p) => p.n).filter((n) => !this.ready.has(n))
          .sort((a, b) => Math.abs(a - 1 - this.visible) - Math.abs(b - 1 - this.visible));
        if (!near.length) break;
        const n = near[0];
        const r = await exec("pdftoppm", ["-png", "-r", String(DPI), "-f", String(n), "-l", String(n), "-singlefile", this.path, `${this.dir}/p${n}`], { timeout: 120000 });
        if (r.code !== 0) { this.error = r.stderr.trim() || `Could not render page ${n}`; break; }
        this.ready.add(n);
        cx.notify();
      }
      this.rendering = false;
      cx.notify();
    });
  }

  pageWidth() {
    return Math.max(200, Math.min(this.width - 48, 1100) * ZOOMS[this.zoom]);
  }

  sizes() {
    const w = this.pageWidth();
    return this.pages.map((p) => Math.round((w * p.size[1]) / p.size[0]) + GAP);
  }

  go(index) {
    const n = Math.max(0, Math.min(this.pages.length - 1, index));
    this.visible = n;
    this.scroll.scroll_to_item(n);
  }

  key(e, cx) {
    const m = e.modifiers;
    if (m.control || m.platform || m.alt || !this.handle.is_focused()) return;
    const k = e.key_char && e.key_char.length === 1 && e.key_char.trim() ? e.key_char : e.key;
    if (k === "j" || k === "down" || k === "l" || k === "right" || k === "space") this.go(this.visible + 1);
    else if (k === "k" || k === "up" || k === "h" || k === "left") this.go(this.visible - 1);
    else if (k === "g") this.go(0);
    else if (k === "G") this.go(this.pages.length - 1);
    else if (k === "+" || k === "=") this.zoom = Math.min(ZOOMS.length - 1, this.zoom + 1);
    else if (k === "-") this.zoom = Math.max(0, this.zoom - 1);
    else if (k === "0") this.zoom = 3;
    else if (k === "o") exec("open", [this.path]);
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  page(t, p) {
    const w = this.pageWidth(), h = Math.round((w * p.size[1]) / p.size[0]);
    return h_flex().w_full().h(h + GAP).flex_none().justify_center().pt(GAP / 2)
      .child(div().w(w).h(h).flex_none().rounded(3).bg("#ffffff").overflow_hidden().border_1().border_color(t.border)
        .when(this.ready.has(p.n), (e) => e.child(image(`data/pdf/${this.key}/p${p.n}.png`).size_full()))
        .when(!this.ready.has(p.n), (e) => e.flex().items_center().justify_center().text_color("#6b7280").text_size(12).child(`Rendering page ${p.n}…`)));
  }

  render() {
    const t = theme();
    const button = (id, label, action) => div().id(id).px(8).py(3).rounded(5).cursor_pointer().text_color(t.muted)
      .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click((_e, cx) => { action(); cx.notify(); }).child(label);
    const done = this.ready.size;
    return v_flex().id("root").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .on_size_change((size, cx) => { if (Math.abs(size.width - this.width) > 1) { this.width = size.width; cx.notify(); } })
      .size_full().bg(t.canvas ?? t.background).text_color(t.foreground).text_size(12.5)
      .child(h_flex().h(42).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border).bg(t.surface)
        .child(div().flex_none().px(5).rounded(4).bg(t.blocked).text_color(t.background).text_size(10.5).font_semibold().child("PDF"))
        .child(div().flex_1().min_w(0).truncate().font_semibold().child(this.title ?? this.name))
        .when(Boolean(this.title), (e) => e.child(div().flex_none().max_w(260).truncate().text_size(11.5).text_color(t.dim).child(this.name)))
        .when(this.pages.length > 0, (e) => e.child(div().flex_none().text_size(11.5).text_color(t.muted)
          .child(`page ${Math.min(this.visible + 1, this.pages.length)} / ${this.pages.length}${done < this.pages.length ? ` · rendered ${done}` : ""}`)))
        .child(button("pdf-zoom-out", "−", () => { this.zoom = Math.max(0, this.zoom - 1); }))
        .child(div().flex_none().w(40).text_center().text_size(11.5).text_color(t.muted).child(`${Math.round(ZOOMS[this.zoom] * 100)}%`))
        .child(button("pdf-zoom-in", "+", () => { this.zoom = Math.min(ZOOMS.length - 1, this.zoom + 1); }))
        .child(button("pdf-open", "Open in Preview ↗", () => exec("open", [this.path]))))
      .when(Boolean(this.error), (el) => el.child(div().px(14).py(8).text_color(t.blocked).child(this.error)))
      .child(div().flex_1().min_h(0).relative()
        .child(v_virtual_list("pdf-pages", this.pages.length, this.sizes(), (i) => String(i), (range) => {
          const measuring = this.pages.length > 1 && range.start === this.pages.length - 1 && range.end - range.start === 1;
          if (!measuring) this.visible = range.start;
          return this.pages.slice(range.start, range.end).map((p) => this.page(t, p));
        }).track_scroll(this.scroll).size_full())
        .child(Scrollbar.vertical("pdf-pages").viewport_from_layout().absolute().inset_0()));
  }
}
