import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, focused, nextCommand, run, setShared, spaces, theme } from "herdr";
import { TIER_ICON, classifyPr } from "./tier.js";

const TIER_CACHE = "dotfiles.pr-tiers";

const REFRESH_MS = 120000;
const FIELDS = "number,title,repository,url,author,updatedAt,isDraft";
const SECTIONS = [
  { id: "review", title: "Needs my review", flags: ["--review-requested", "@me"], query: [] },
  { id: "mine", title: "My pull requests", flags: ["--author", "@me"], query: [] },
  { id: "involved", title: "Involved", flags: ["--involves", "@me"], query: ["--", "-author:@me", "-review-requested:@me"] },
];

function openPr(pr) {
  const args = { mod: "pr-view", props: { url: pr.url }, name: `#${pr.number}` };
  let space = focused()?.space ?? spaces().find((s) => s.active)?.id;
  if (!space) {
    run("space.new", { name: "Reviews" });
    space = spaces().find((s) => s.name === "Reviews")?.id;
  }
  run("tab.new", space ? { ...args, space } : args);
}

function age(iso) {
  const minutes = Math.max(0, Math.round((Date.now() - Date.parse(iso)) / 60000));
  if (minutes < 60) return `${minutes}m`;
  if (minutes < 1440) return `${Math.round(minutes / 60)}h`;
  return `${Math.round(minutes / 1440)}d`;
}

export default class PullRequests extends View {
  init(_props, cx) {
    this.data = {};
    this.error = null;
    this.loading = false;
    this.collapsed = {};
    this.focusInit(cx);
    this.tiers = {};
    try { this.tiers = JSON.parse(localStorage.getItem(TIER_CACHE) ?? "{}"); } catch {}
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.notify();
    cx.spawn(async (cx) => {
      const results = await Promise.all(SECTIONS.map(async (s) => {
        try {
          const r = await exec("gh", ["search", "prs", "--state", "open", ...s.flags, "--json", FIELDS, "--limit", "30", ...s.query], { timeout: 60000 });
          if (r.code !== 0) return [s.id, null, r.stderr.trim() || `gh exited ${r.code}`];
          return [s.id, JSON.parse(r.stdout), null];
        } catch (e) {
          return [s.id, null, String(e)];
        }
      }));
      this.error = null;
      for (const [id, list, err] of results) {
        if (list) this.data[id] = list.sort((a, b) => Date.parse(b.updatedAt) - Date.parse(a.updatedAt));
        if (err) this.error = err;
      }
      if (this.data.review) setShared("dotfiles.reviews", this.data.review.length);
      this.loading = false;
      this.updated = new Date();
      this.classify(cx);
      cx.notify();
    });
  }


  focusInit(cx) {
    this.handle = cx.focus_handle();
    this.sel = 0;
    cx.spawn(async (cx) => {
      for (;;) {
        if ((await nextCommand()) === "focus") { this.handle.focus(); cx.notify(); }
      }
    });
  }

  listKey(e, cx, items, open) {
    const m = e.modifiers;
    if (m.control || m.platform || m.alt) return;
    const last = items.length - 1;
    if (e.key === "j" || e.key === "down") this.sel = Math.min(last, this.sel + 1);
    else if (e.key === "k" || e.key === "up") this.sel = Math.max(0, this.sel - 1);
    else if (e.key === "g" && m.shift) this.sel = last;
    else if (e.key === "g") this.sel = 0;
    else if (e.key === "enter" && items[this.sel]) open(items[this.sel]);
    else if (e.key === "r") this.refresh(cx);
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  focusedRow(index) {
    return this.handle?.is_focused() && index === this.sel;
  }

  visible() {
    return SECTIONS.flatMap((s) => (this.collapsed[s.id] ? [] : this.data[s.id] ?? []));
  }

  classify(cx) {
    if (this.classifying) return;
    const todo = [...new Map(SECTIONS.flatMap((s) => this.data[s.id] ?? []).map((pr) => [pr.url, pr])).values()]
      .filter((pr) => this.tiers[pr.url]?.updatedAt !== pr.updatedAt);
    if (!todo.length) return;
    this.classifying = true;
    cx.spawn(async (cx) => {
      for (let i = 0; i < todo.length; i += 4) {
        await Promise.all(todo.slice(i, i + 4).map(async (pr) => {
          try {
            const r = await exec("gh", ["pr", "view", pr.url, "--json", "files"], { timeout: 60000 });
            if (r.code !== 0) return;
            const { tier, reason } = classifyPr(JSON.parse(r.stdout).files);
            this.tiers[pr.url] = { updatedAt: pr.updatedAt, tier, reason };
          } catch {}
        }));
        cx.notify();
      }
      try { localStorage.setItem(TIER_CACHE, JSON.stringify(this.tiers)); } catch {}
      this.classifying = false;
      cx.notify();
    });
  }

  tierChip(t, pr) {
    const tier = this.tiers[pr.url]?.tier;
    if (!tier) return div().flex_none().w(16);
    const color = { trunk: t.ansi13 ?? t.accent, branch: t.ansi2 ?? t.done, leaf: t.ansi6 ?? t.working }[tier];
    return div().flex_none().w(16).text_color(color).child(TIER_ICON[tier]);
  }

  row(t, pr) {
    const selected = this.focusedRow(this.visible().indexOf(pr));
    return v_flex().id(`pr-${pr.url}`).w_full().min_w(0).px(12).py(6).gap(2).rounded(6).cursor_pointer()
      .when(selected, (e) => e.bg(t.selected))
      .hover((s) => s.bg(t.hover))
      .on_click(() => openPr(pr))
      .child(h_flex().w_full().min_w(0).gap(6).items_center()
        .child(this.tierChip(t, pr))
        .child(div().flex_none().text_color(pr.isDraft ? t.dim : t.accent).child(`#${pr.number}`))
        .child(div().flex_1().min_w(0).truncate().text_color(pr.isDraft ? t.muted : t.foreground).child(pr.title)))
      .child(h_flex().w_full().min_w(0).gap(8).text_size(11).text_color(t.dim)
        .child(div().flex_1().min_w(0).truncate().child(pr.repository?.nameWithOwner ?? ""))
        .child(div().child(pr.author?.login ?? ""))
        .child(div().child(age(pr.updatedAt))));
  }

  section(t, s) {
    const list = this.data[s.id];
    const open = !this.collapsed[s.id];
    return v_flex().gap(2)
      .child(h_flex().id(`sec-${s.id}`).px(12).pt(10).pb(4).gap(6).items_center().cursor_pointer()
        .on_click((_e, cx) => { this.collapsed[s.id] = open; cx.notify(); })
        .child(div().text_color(t.dim).child(open ? "▾" : "▸"))
        .child(div().flex_1().font_semibold().text_size(11.5).text_color(t.muted).child(s.title.toUpperCase()))
        .child(div().text_color(t.dim).child(list ? String(list.length) : "…")))
      .when(open && Boolean(list) && list.length === 0, (el) => el.child(div().px(12).text_color(t.dim).child("Nothing here")))
      .when(open && Boolean(list), (el) => el.children(list.map((pr) => this.row(t, pr))));
  }

  render() {
    const t = theme();
    const pad = (n) => String(n).padStart(2, "0");
    const stamp = this.updated ? `${pad(this.updated.getHours())}:${pad(this.updated.getMinutes())}` : "";
    return v_flex().id("root").track_focus(this.handle).on_key_down((e, cx) => this.listKey(e, cx, this.visible(), openPr))
      .size_full().bg(t.surface).text_size(12.5).text_color(t.foreground)
      .child(h_flex().h(40).px(12).items_center().gap(8).border_b(1).border_color(t.border)
        .child(div().flex_1().font_semibold().child("Pull requests"))
        .child(div().text_size(11).text_color(t.dim).child(this.loading ? "refreshing…" : stamp))
        .child(div().id("pr-refresh").px(6).rounded(4).cursor_pointer().text_color(t.muted).hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => this.refresh(cx)).child("↻")))
      .when(Boolean(this.error), (el) => el.child(div().px(12).py(6).text_size(11).text_color(t.blocked).child(this.error)))
      .child(v_flex().id("pr-list").w_full().flex_1().min_h(0).overflow_y_scrollbar().pb(10)
        .children(SECTIONS.map((s) => this.section(t, s))));
  }
}
