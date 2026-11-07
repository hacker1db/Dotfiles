import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, focused, nextCommand, notify, run, setShared, spaces, theme } from "herdr";

const REFRESH_MS = 60000;
const FILTERS = ["active", "completed", "archived", "all"];

function day(iso) {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? "" : d.toLocaleDateString([], { month: "short", day: "numeric" });
}

export default class Plans extends View {
  init(_props, cx) {
    this.plans = [];
    this.filter = "active";
    this.error = null;
    this.loading = false;
    this.focusInit(cx);
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const r = await exec("plan", ["list", "--json"], { timeout: 30000 });
        if (r.code !== 0) throw new Error(r.stderr.trim() || `plan exited ${r.code}`);
        this.plans = (JSON.parse(r.stdout).plans ?? []).sort((a, b) => Date.parse(b.updated) - Date.parse(a.updated));
        this.error = null;
        setShared("dotfiles.plans", this.plans.filter((p) => p.status === "active").length);
      } catch (e) {
        this.error = String(e.message ?? e);
      }
      this.loading = false;
      cx.notify();
    });
  }

  setStatus(plan, status, cx) {
    cx.spawn(async (cx) => {
      const r = await exec("plan", ["status", plan.id, status, "--json"], { timeout: 30000 });
      if (r.code !== 0) notify({ title: "Plan status not changed", body: r.stderr.trim(), level: "error" });
      else notify({ title: `Plan ${status}`, body: plan.title, level: "success", timeout: 3000 });
      this.loading = false;
      this.refresh(cx);
    });
  }

  open(plan) {
    const mod = "plan-view";
    const props = { path: plan.path, id: plan.id };
    const name = plan.title;
    const f = focused();
    if (f?.pane) run("pane.split", { direction: "right", pane: f.pane, mod, props });
    else if (f?.space) run("tab.new", { space: f.space, mod, props, name });
    else {
      const before = new Set(spaces().map((s) => s.id));
      run("space.new", { name: "Plans", folder: plan.path.replace(/\/[^/]*$/, "") });
      const space = spaces().find((s) => !before.has(s.id));
      run("tab.new", { ...(space ? { space: space.id } : {}), mod, props, name });
    }
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

  shown() {
    return this.filter === "all" ? this.plans : this.plans.filter((p) => p.status === this.filter);
  }

  row(t, plan) {
    const selected = this.focusedRow(this.shown().indexOf(plan));
    const color = { active: t.working, completed: t.done, archived: t.dim }[plan.status] ?? t.muted;
    const button = (id, label, action) => div().id(id).flex_none().px(6).rounded(4).cursor_pointer().text_color(t.muted)
      .hover((s) => s.bg(t.raised).text_color(t.foreground))
      .on_click((_e, cx) => { cx.stop_propagation(); action(cx); }).child(label);
    return h_flex().id(`plan-${plan.id}`).w_full().min_w(0).px(12).py(6).gap(8).items_center().rounded(6).cursor_pointer()
      .when(selected, (e) => e.bg(t.selected))
      .hover((s) => s.bg(t.hover))
      .on_click(() => this.open(plan))
      .child(div().flex_none().size(7).rounded(4).bg(color))
      .child(v_flex().flex_1().min_w(0).gap(2)
        .child(div().w_full().truncate().child(plan.title))
        .child(h_flex().gap(8).text_size(11).text_color(t.dim)
          .child(div().child(plan.status))
          .child(div().child(day(plan.updated)))
          .when((plan.tags ?? []).length > 0, (el) => el.child(div().truncate().child(plan.tags.join(" · "))))))
      .child(button(`plan-open-${plan.id}`, "↗", () => exec("plan", ["open", plan.id])))
      .when(plan.status === "active", (el) => el.child(button(`plan-done-${plan.id}`, "✓", (cx) => this.setStatus(plan, "completed", cx))))
      .when(plan.status !== "active", (el) => el.child(button(`plan-reopen-${plan.id}`, "↺", (cx) => this.setStatus(plan, "active", cx))));
  }

  render() {
    const t = theme();
    const shown = this.filter === "all" ? this.plans : this.plans.filter((p) => p.status === this.filter);
    const count = (f) => (f === "all" ? this.plans : this.plans.filter((p) => p.status === f)).length;
    return v_flex().id("root").track_focus(this.handle).on_key_down((e, cx) => this.listKey(e, cx, this.shown(), (p) => this.open(p)))
      .size_full().bg(t.surface).text_size(12.5).text_color(t.foreground)
      .child(h_flex().h(40).px(12).items_center().gap(8).border_b(1).border_color(t.border)
        .child(div().flex_1().font_semibold().child("Plans"))
        .child(div().text_size(11).text_color(t.dim).child(this.loading ? "refreshing…" : ""))
        .child(div().id("plans-refresh").px(6).rounded(4).cursor_pointer().text_color(t.muted).hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => this.refresh(cx)).child("↻")))
      .child(h_flex().px(8).py(6).gap(4).children(FILTERS.map((f) =>
        div().id(`filter-${f}`).px(8).py(2).rounded(5).cursor_pointer().text_size(11.5)
          .bg(this.filter === f ? t.selected : t.surface).text_color(this.filter === f ? t.foreground : t.muted)
          .hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => { this.filter = f; cx.notify(); })
          .child(`${f} ${count(f)}`))))
      .when(Boolean(this.error), (el) => el.child(div().px(12).py(6).text_size(11).text_color(t.blocked).child(this.error)))
      .child(v_flex().id("plans-list").w_full().flex_1().min_h(0).overflow_y_scrollbar().pb(10)
        .when(shown.length === 0 && !this.loading, (el) => el.child(div().px(12).py(8).text_color(t.dim).child("No plans")))
        .children(shown.map((p) => this.row(t, p))));
  }
}
