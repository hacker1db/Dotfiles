import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, hc, nextCommand, notify, openOverlay, theme } from "herdr";

const REFRESH_MS = 15000;
const STATUS = {
  QUESTION: ["?", "blocked", "asking"],
  WAITING: ["⚠", "blocked", "waiting"],
  BUSY: ["⠋", "working", "working"],
  DONE: ["✓", "done", "done"],
  IDLE: ["○", "idle", "idle"],
};
const ORDER = ["QUESTION", "WAITING", "DONE", "BUSY", "IDLE"];

function rank(a) {
  const i = ORDER.indexOf(a.status);
  return (a.needsAttention ? -10 : 0) + (i < 0 ? ORDER.length : i);
}

export default class Fleet extends View {
  init(_props, cx) {
    this.agents = [];
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
        const r = await exec("fleet", ["list", "--json"], { timeout: 30000 });
        if (r.code !== 0) throw new Error(r.stderr.trim() || `fleet exited ${r.code}`);
        this.agents = (JSON.parse(r.stdout).agents ?? []).sort((a, b) => rank(a) - rank(b) || (b.ts ?? 0) - (a.ts ?? 0));
        this.error = null;
      } catch (e) {
        this.error = String(e.message ?? e);
      }
      this.loading = false;
      cx.notify();
    });
  }

  open(agent) {
    const script = 'inherdr() { p=$1; for _ in 1 2 3 4 5 6; do p=$(ps -o ppid= -p "$p" | tr -d " "); [ -n "$p" ] && [ "$p" != 1 ] || return 1; ps -o comm= -p "$p" | grep -q herdr && return 0; done; return 1; }; ' +
      'c=$(tmux list-clients -F "#{client_activity} #{client_pid} #{client_name}" | sort -rn | while read -r _ pid name; do case "$name" in /dev/*) inherdr "$pid" || { echo "$name"; break; } ;; esac; done); ' +
      '[ -n "$c" ] || { echo "no tmux client is attached" >&2; exit 1; }; ' +
      'tmux switch-client -c "$c" -t "$1" && tmux select-window -t "$2" && tmux select-pane -t "$3" && open -a Ghostty';
    exec("/bin/sh", ["-c", script, "sh", `=${agent.session}`, agent.windowId, agent.pane]).then((r) => {
      if (r.code !== 0) notify({ title: "Could not switch tmux", body: r.stderr.trim(), level: "error" });
    });
  }

  dashboard(cx) {
    const pending = hc(["run", "--json", "--bg", "--rm", "--no-parent", "--", "fleet"]);
    cx.spawn(async () => {
      const result = await pending;
      let address = null;
      try { address = JSON.parse(result.stdout).address; } catch {}
      if (!address) return notify({ title: "fleet did not start", body: result.stderr.trim(), level: "error" });
      openOverlay({ kind: "dialog", width: 0.85, height: 0.8, layout: { type: "block", content: { terminal: address } } });
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

  ordered() {
    const sessions = [];
    for (const agent of this.agents) {
      let group = sessions.find((g) => g.name === agent.session);
      if (!group) sessions.push(group = { name: agent.session, agents: [] });
      group.agents.push(agent);
    }
    return sessions;
  }

  row(t, agent) {
    const selected = this.focusedRow(this.ordered().flatMap((g) => g.agents).indexOf(agent));
    const [glyph, colorName, word] = STATUS[agent.status] ?? ["·", "unknown", (agent.status ?? "").toLowerCase()];
    const color = t[colorName] ?? t.muted;
    const where = agent.git?.branch ?? agent.branch ?? "";
    return h_flex().id(`agent-${agent.pane}`).w_full().min_w(0).px(12).py(6).gap(10).items_center().rounded(6).cursor_pointer()
      .when(selected, (e) => e.bg(t.selected))
      .when(agent.needsAttention, (e) => e.bg(t.raised))
      .hover((s) => s.bg(t.hover))
      .on_click(() => this.open(agent))
      .child(div().w(14).flex_none().text_color(color).child(glyph))
      .child(v_flex().flex_1().min_w(0).gap(2)
        .child(h_flex().w_full().min_w(0).gap(6)
          .child(div().flex_1().min_w(0).truncate().child(agent.windowLabel ?? agent.window ?? agent.pane))
          .child(div().flex_none().text_size(11).text_color(color).child(word)))
        .child(h_flex().w_full().min_w(0).gap(8).text_size(11).text_color(t.dim)
          .child(div().flex_none().child(agent.label ?? agent.agentType ?? ""))
          .child(div().flex_1().min_w(0).truncate().child(where))));
  }

  render() {
    const t = theme();
    const sessions = [];
    for (const agent of this.agents) {
      let group = sessions.find((g) => g.name === agent.session);
      if (!group) sessions.push(group = { name: agent.session, agents: [] });
      group.agents.push(agent);
    }
    const waiting = this.agents.filter((a) => a.needsAttention).length;
    const button = (id, label, action) => div().id(id).px(6).rounded(4).cursor_pointer().text_color(t.muted)
      .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(action).child(label);
    return v_flex().id("root").track_focus(this.handle).on_key_down((e, cx) => this.listKey(e, cx, this.ordered().flatMap((g) => g.agents), (a) => this.open(a)))
      .size_full().bg(t.surface).text_size(12.5).text_color(t.foreground)
      .child(h_flex().h(40).px(12).items_center().gap(8).border_b(1).border_color(t.border)
        .child(div().flex_1().font_semibold().child("Fleet"))
        .child(div().text_size(11).text_color(waiting ? t.blocked : t.dim).child(this.loading ? "refreshing…" : `${this.agents.length} agents${waiting ? ` · ${waiting} waiting` : ""}`))
        .child(button("fleet-dashboard", "▤", (_e, cx) => this.dashboard(cx)))
        .child(button("fleet-refresh", "↻", (_e, cx) => this.refresh(cx))))
      .when(Boolean(this.error), (el) => el.child(div().px(12).py(6).text_size(11).text_color(t.blocked).child(this.error)))
      .child(v_flex().id("fleet-list").w_full().flex_1().min_h(0).overflow_y_scrollbar().pb(10)
        .when(!this.agents.length && !this.loading && !this.error, (el) => el.child(div().px(12).py(8).text_color(t.dim).child("No agents in tmux")))
        .children(sessions.map((g) => v_flex().w_full().gap(2)
          .child(h_flex().px(12).pt(10).pb(4).gap(6)
            .child(div().flex_1().font_semibold().text_size(11.5).text_color(t.muted).child(g.name.toUpperCase()))
            .child(div().text_color(t.dim).text_size(11).child(String(g.agents.length))))
          .children(g.agents.map((a) => this.row(t, a))))));
  }
}
