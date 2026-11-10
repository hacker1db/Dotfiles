import { View, div, image } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { appHome, exec, focused, nextCommand, notify, props, readTextFile, run, theme, watchFolder, writeTextFile } from "herdr";

const POLL_MS = 5000;
const MERMAID = /^[ \t]*(`{3,}|~{3,})[ \t]*mermaid\b[^\n]*\r?\n([\s\S]*?)^[ \t]*\1[ \t]*\r?$/gim;
const MERMAID_SCALE = 2;

function hash(text) {
  let h = 5381;
  for (let i = 0; i < text.length; i++) h = ((h << 5) + h + text.charCodeAt(i)) >>> 0;
  return h.toString(16);
}

function segments(body) {
  const out = [];
  let last = 0;
  for (const m of body.matchAll(MERMAID)) {
    if (m.index > last) out.push({ md: body.slice(last, m.index) });
    out.push({ mermaid: m[2], key: `v1-${hash(m[2])}` });
    last = m.index + m[0].length;
  }
  if (last < body.length) out.push({ md: body.slice(last) });
  return out.filter((s) => s.mermaid || s.md.trim());
}
const READ_WIDTH = 760;
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function scalar(raw) {
  const v = raw.trim();
  if (/^'.*'$/.test(v)) return v.slice(1, -1).replace(/''/g, "'");
  if (/^".*"$/.test(v)) return v.slice(1, -1).replace(/\\"/g, "\"");
  return v;
}

function parse(text) {
  const m = /^---\r?\n([\s\S]*?)\r?\n---[ \t]*(?:\r?\n|$)/.exec(text);
  const meta = {};
  if (!m) return { meta, body: text };
  let list = null;
  for (const line of m[1].split(/\r?\n/)) {
    const item = /^\s+-\s+(.*)$/.exec(line);
    if (item && list) { meta[list].push(scalar(item[1])); continue; }
    const kv = /^([A-Za-z_][\w-]*):\s*(.*)$/.exec(line);
    if (!kv) continue;
    const [, key, value] = kv;
    list = null;
    if (value === "") { meta[key] = []; list = key; }
    else if (/^\[.*\]$/.test(value.trim())) meta[key] = value.trim().slice(1, -1).split(",").map(scalar).filter(Boolean);
    else meta[key] = scalar(value);
  }
  return { meta, body: text.slice(m[0].length) };
}

function split(text) {
  const { meta, body } = parse(text);
  let rest = body.replace(/^\s+/, "");
  let heading = null;
  const h1 = /^#[ \t]+(.+?)[ \t#]*(?:\r?\n|$)/.exec(rest);
  if (h1) { heading = h1[1].trim(); rest = rest.slice(h1[0].length).replace(/^\s*(?:---|\*\*\*)\s*\n/, ""); }
  rest = rest.replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, "$2").replace(/\[\[([^\]]+)\]\]/g, "$1");
  return { meta, heading, body: rest };
}

function date(iso) {
  const d = new Date(iso);
  return !iso || Number.isNaN(d.getTime()) ? "" : `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

export default class PlanView extends View {
  init(p, cx) {
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      for (;;) {
        if ((await nextCommand()) === "focus") { this.handle.focus(); cx.notify(); }
      }
    });
    this.path = p?.path ?? props()?.path ?? "";
    this.id = p?.id ?? props()?.id ?? null;
    this.text = null;
    this.doc = null;
    this.error = this.path ? null : "No plan path given";
    this.busy = false;
    this.reload(cx);
    this.watch(cx);
  }

  dir() {
    return this.path.replace(/\/[^/]*$/, "") || "/";
  }

  reload(cx) {
    if (!this.path) return;
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(this.path);
        if (text === null) { this.error = "This plan file is no longer available"; cx.notify(); return; }
        if (text === this.text && !this.error) return;
        this.text = text;
        this.doc = split(text);
        this.parts = segments(this.doc.body);
        this.error = null;
        this.renderDiagrams(cx);
      } catch (e) {
        this.error = String(e.message ?? e);
      }
      cx.notify();
    });
  }

  renderDiagrams(cx) {
    this.diagrams ??= {};
    const todo = this.parts.filter((p) => p.mermaid && !this.diagrams[p.key]);
    if (!todo.length) return;
    for (const p of todo) this.diagrams[p.key] = { status: "pending" };
    cx.spawn(async (cx) => {
      const dir = `${appHome()}/data/mermaid`;
      await exec("mkdir", ["-p", dir]);
      for (const p of todo) {
        const png = `${dir}/${p.key}.png`, src = `${dir}/${p.key}.mmd`;
        try {
          if ((await exec("test", ["-s", png])).code !== 0) {
            await writeTextFile(src, p.mermaid, await readTextFile(src));
            const r = await exec("mmdc", ["-i", src, "-o", png, "-c", `${appHome()}/mods/plan-view/mermaid.json`, "-b", "transparent", "-s", String(MERMAID_SCALE), "-q"], { timeout: 120000 });
            if (r.code !== 0) throw new Error(r.stderr.trim().split("\n").slice(-3).join("\n") || "mmdc failed (is mermaid-cli installed?)");
          }
          const dims = await exec("sips", ["-g", "pixelWidth", "-g", "pixelHeight", png]);
          const w = Number(/pixelWidth: (\d+)/.exec(dims.stdout)?.[1] ?? 0) / MERMAID_SCALE;
          const h = Number(/pixelHeight: (\d+)/.exec(dims.stdout)?.[1] ?? 0) / MERMAID_SCALE;
          this.diagrams[p.key] = { status: "ready", w, h };
        } catch (e) {
          this.diagrams[p.key] = { status: "error", error: String(e.message ?? e) };
        }
        cx.notify();
      }
    });
  }

  diagram(t, part) {
    const d = this.diagrams?.[part.key] ?? { status: "pending" };
    if (d.status === "ready" && d.w > 0) {
      const w = Math.min(d.w, READ_WIDTH), h = Math.round((d.h * w) / d.w);
      return h_flex().w_full().justify_center().py(12).child(image(`data/mermaid/${part.key}.png`).w(w).h(h));
    }
    if (d.status === "error") {
      return v_flex().gap(6).my(8).p(12).rounded(8).border_1().border_color(t.blocked)
        .child(div().text_size(12).text_color(t.blocked).child(`Mermaid diagram did not render: ${d.error}`))
        .child(TextView.markdown(`pv-mermaid-src-${part.key}`, "```mermaid\n" + part.mermaid + "```").selectable(true));
    }
    return h_flex().w_full().h(80).my(8).items_center().justify_center().rounded(8).border_1().border_color(t.border).bg(t.surface)
      .text_size(12).text_color(t.dim).child("Rendering diagram…");
  }

  watch(cx) {
    if (!this.path) return;
    const dir = this.dir();
    cx.spawn(async (cx) => {
      try {
        for (;;) {
          const changed = await watchFolder(dir);
          if (changed.some((p) => p === this.path || p === dir)) this.reload(cx);
        }
      } catch {
        cx.timer.every(POLL_MS, (cx) => this.reload(cx));
      }
    });
  }

  planId() {
    return this.id ?? this.doc?.meta.id ?? null;
  }

  setStatus(status, cx) {
    const id = this.planId();
    if (!id || this.busy) return;
    this.busy = true;
    cx.notify();
    cx.spawn(async (cx) => {
      const r = await exec("plan", ["status", id, status, "--json"], { timeout: 30000 });
      if (r.code !== 0) notify({ title: "Plan status not changed", body: r.stderr.trim(), level: "error" });
      else notify({ title: `Plan ${status}`, body: this.doc?.meta.title ?? "", level: "success", timeout: 3000 });
      this.busy = false;
      this.reload(cx);
      cx.notify();
    });
  }

  edit() {
    const argv = ["/bin/zsh", "-lc", "exec ${EDITOR:-nvim} \"$1\"", "plan-view", this.path];
    const f = focused();
    if (f?.pane) run("pane.split", { direction: "right", pane: f.pane, argv });
    else run("terminal.open", { argv, folder: this.dir(), place: "tab" });
  }

  action(t, id, label, onClick, primary) {
    return div().id(id).flex_none().h(26).px(10).flex().items_center().rounded(6).cursor_pointer().text_size(12)
      .border(1).border_color(primary ? t.accent : t.border)
      .bg(primary ? t.accent : t.surface).text_color(primary ? t.accent_foreground : t.muted)
      .hover((s) => primary ? s.opacity(0.9) : s.bg(t.hover).text_color(t.foreground))
      .on_click((_e, cx) => { cx.stop_propagation(); onClick(cx); })
      .child(label);
  }

  header(t) {
    const meta = this.doc?.meta ?? {};
    const status = meta.status ?? "unknown";
    const color = { active: t.working, completed: t.done, archived: t.dim }[status] ?? t.muted;
    const tags = Array.isArray(meta.tags) ? meta.tags : [];
    const title = (this.doc?.heading || meta.title || this.path.split("/").pop()).replace(/`/g, "");
    const slug = (s) => String(s ?? "").toLowerCase().replace(/\.md$/, "").replace(/[^a-z0-9]+/g, "");
    const showFile = Boolean(meta.title && this.doc?.heading && slug(meta.title) !== slug(title) && slug(meta.title) !== slug(this.path.split("/").pop()));
    const dates = [
      meta.created ? `Created ${date(meta.created)}` : "",
      meta.updated && date(meta.updated) !== date(meta.created) ? `Updated ${date(meta.updated)}` : "",
    ].filter(Boolean);
    return v_flex().w_full().gap(12).pb(22).mb(26).border_b(1).border_color(t.border)
      .child(h_flex().gap(10).items_center().flex_wrap()
        .child(h_flex().flex_none().h(22).px(9).gap(6).items_center().rounded(11).bg(t.raised).border(1).border_color(t.border)
          .child(div().size(7).rounded(4).bg(color))
          .child(div().text_size(11.5).font_semibold().text_color(color).child(status)))
        .children(dates.map((d, i) => div().text_size(12).text_color(t.dim).child(i === 0 ? d : `·  ${d}`))))
      .child(div().w_full().text_size(26).line_height("34px").font_weight(700).text_color(t.foreground).child(title))
      .when(showFile, (el) => el.child(div().text_size(12).text_color(t.dim).child(meta.title)))
      .when(tags.length > 0, (el) => el.child(h_flex().gap(6).flex_wrap().children(tags.map((tag, i) =>
        div().id(`tag-${i}`).h(22).px(9).flex().items_center().rounded(6).bg(t.raised).text_size(11.5).text_color(t.muted).child(`#${tag}`)))));
  }

  render() {
    const t = theme();
    const id = this.planId();
    const status = this.doc?.meta.status;
    return v_flex().id("root").track_focus(this.handle).size_full().bg(t.background).text_color(t.foreground)
      .child(h_flex().h(44).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border).bg(t.surface)
        .child(div().flex_none().text_size(12).font_semibold().text_color(t.muted).child("Plan"))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(this.path.split("/").pop()))
        .when(this.busy, (el) => el.child(div().text_size(11).text_color(t.dim).child("updating…")))
        .when(Boolean(id), (el) => el.child(this.action(t, "pv-dashboard", "Dashboard ↗", () => exec("plan", ["open", id])))
          .child(this.action(t, "pv-edit", "Edit", () => this.edit()))
          .when(status === "active", (el) => el.child(this.action(t, "pv-done", "✓ Mark completed", (cx) => this.setStatus("completed", cx), true)))
          .when(Boolean(status) && status !== "active", (el) => el.child(this.action(t, "pv-reopen", "↺ Reopen", (cx) => this.setStatus("active", cx))))))
      .child(v_flex().id("pv-scroll").w_full().flex_1().min_h(0).overflow_y_scrollbar()
        .child(v_flex().w_full().max_w(READ_WIDTH + 96).mx_auto().px(48).pt(36).pb(64)
          .when(Boolean(this.error), (el) => el.child(div().p(12).rounded(8).bg(t.raised).text_size(13).text_color(t.blocked).child(this.error)))
          .when(!this.doc && !this.error, (el) => el.child(div().text_size(13).text_color(t.dim).child("Loading plan…")))
          .when(Boolean(this.doc), (el) => el.child(this.header(t))
            .child(div().w_full().text_size(14.5).line_height("24px").font_weight(400).text_color(t.foreground)
              .children((this.parts ?? []).map((part, i) => part.mermaid
                ? this.diagram(t, part)
                : TextView.markdown(`pv-body-${i}`, part.md).selectable(true)))))));
  }
}
