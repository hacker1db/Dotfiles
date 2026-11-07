import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { agents, appHome, exec, focused, hc, home, layout, nextCommand, panes, readTextFile, run, setShared, shared, spaces, theme } from "herdr";

const SONG_MS = 5000;
const REVIEWS_MS = 300000;
const PLANS_MS = 120000;
const FLEET_MS = 20000;
const WATCH_MS = 1500;
const SYNC_MS = 60000;
const RESOLVE_ROOT = 'cd -P "$1" && cd ../../.. && printf %s "$PWD"';
const NAV = { "nav-left": ["left", "ctrl+h"], "nav-down": ["down", "ctrl+j"], "nav-up": ["up", "ctrl+k"], "nav-right": ["right", "ctrl+l"] };
const PASS_THROUGH = ["nvim", "vim", "tmux"];

async function runsTmux(terminal) {
  try {
    const info = JSON.parse((await hc(["get", terminal, "--json"])).stdout);
    if (!info.pid || String(info.terminal ?? terminal).includes("/")) return false;
    return (await exec("pgrep", ["-P", String(info.pid), "-x", "tmux"], { timeout: 2000 })).code === 0;
  } catch {
    return false;
  }
}

async function navigate(command) {
  if (command === "prefix") {
    const f = focused();
    const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
    if (pane?.terminal && (pane.program?.key === "tmux" || (pane.program?.shell && await runsTmux(pane.terminal)))) hc(["keys", pane.terminal, "ctrl+a"]);
    else run("mod.open", { name: "prefix" });
    return;
  }
  const [direction, key] = NAV[command] ?? [];
  if (!direction) return;
  const f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  if (pane?.terminal && (PASS_THROUGH.includes(pane.program?.key) || (pane.program?.shell && await runsTmux(pane.terminal)))) {
    hc(["keys", pane.terminal, key]);
    return;
  }
  run("pane.go", { direction });
}

function layoutSignature() {
  const tabs = spaces().filter((s) => !s.machine).map((s) => `${s.id}:${s.name}:${s.tabs.map((t) => `${t.id}=${t.name}`).join(",")}`);
  const list = panes().filter((p) => p.terminal).map((p) => `${p.tab}/${p.pane}/${p.terminal}`);
  return `${tabs.join(";")}|${list.sort().join(";")}`;
}

function findNode(tree, id) {
  if (!tree || typeof tree !== "object") return null;
  if (tree.id === id) return tree;
  for (const child of tree.children ?? []) {
    const found = findNode(child, id);
    if (found) return found;
  }
  return null;
}

async function prInTab(tabId) {
  if (!tabId || tabId.includes("/")) return null;
  let doc;
  try { doc = JSON.parse(await readTextFile(`${home()}/.local/state/herdr-core/default/docs.json`))["herdr-app"].value; } catch { return null; }
  const tab = (doc.spaces ?? []).flatMap((s) => s.tabs ?? []).find((t) => t.id === tabId);
  const walk = (n) => {
    if (!n) return null;
    if (n.content?.mod === "pr-view") return n.content.props?.url ?? null;
    for (const c of n.children ?? []) { const url = walk(c); if (url) return url; }
    return null;
  };
  return walk(tab?.root);
}

function followChanges() {
  const stack = findNode(layout(), "panel-body");
  if (!stack || !["changes", "pr-changes"].includes(stack.active)) return;
  const want = shared("dotfiles.activePr") ? "pr-changes" : "changes";
  if (stack.active !== want) run("layout.select", { stack: "panel-body", child: want });
}

function togglePanel(child) {
  const tree = layout();
  const panel = findNode(tree, "panel");
  const stack = findNode(tree, "panel-body");
  if (panel && !panel.hidden && stack?.active === child) return run("layout.hide", { id: "panel" });
  run("layout.select", { stack: "panel-body", child });
  run("layout.show", { id: "panel" });
}

export default class StatusBar extends View {
  init(_props, cx) {
    this.song = null;
    this.reviews = null;
    this.plans = null;
    this.fleet = null;
    this.clock = this.now();
    this.signature = null;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("/bin/sh", ["-c", RESOLVE_ROOT, "sh", `${appHome()}/mods/status-bar`]);
        if (r.code === 0) this.root = r.stdout;
      } catch {}
      this.refreshSong(cx);
      this.syncTmux(cx);
    });
    cx.spawn(async () => {
      for (;;) await navigate(await nextCommand());
    });
    this.refreshFleet(cx);
    cx.timer.every(FLEET_MS, (cx) => this.refreshFleet(cx));
    cx.timer.every(WATCH_MS, (cx) => {
      followChanges();
      const tab = focused()?.tab ?? null;
      const signature = layoutSignature();
      if (tab !== this.activeTab || signature !== this.signature) {
        this.activeTab = tab;
        cx.spawn(async () => {
          const url = await prInTab(tab);
          if (url !== (shared("dotfiles.activePr") ?? null)) setShared("dotfiles.activePr", url);
          followChanges();
        });
      }
      if (signature === this.signature) return;
      this.signature = signature;
      this.syncTmux(cx);
    });
    cx.timer.every(SYNC_MS, (cx) => this.syncTmux(cx));
    this.refreshReviews(cx);
    this.refreshPlans(cx);
    cx.timer.every(SONG_MS, (cx) => {
      this.refreshSong(cx);
      const clock = this.now();
      if (clock !== this.clock) { this.clock = clock; cx.notify(); }
    });
    cx.timer.every(REVIEWS_MS, (cx) => this.refreshReviews(cx));
    cx.timer.every(PLANS_MS, (cx) => this.refreshPlans(cx));
  }

  now() {
    const d = new Date();
    return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  }

  syncTmux(cx) {
    if (!this.root) return;
    cx.spawn(async () => {
      try {
        const r = await exec(`${this.root}/bin/herdr-tmux`, ["sync"], { timeout: 60000 });
        if (r.code !== 0) console.log(`herdr-tmux: ${r.stderr}`);
      } catch (e) {
        console.log(`herdr-tmux: ${e}`);
      }
    });
  }

  refreshFleet(cx) {
    cx.spawn(async (cx) => {
      try {
        const r = await exec("fleet", ["list", "--json"], { timeout: 15000 });
        if (r.code !== 0) return;
        const list = JSON.parse(r.stdout).agents ?? [];
        const fleet = { total: list.length, attention: list.filter((a) => a.needsAttention).length, busy: list.filter((a) => a.status === "BUSY").length };
        if (JSON.stringify(fleet) !== JSON.stringify(this.fleet)) { this.fleet = fleet; cx.notify(); }
      } catch {}
    });
  }

  refreshSong(cx) {
    if (!this.root) return;
    cx.spawn(async (cx) => {
      let song = null;
      try {
        const r = await exec(`${this.root}/bin/current-song`, ["--json"], { timeout: 4000 });
        const np = r.code === 0 && r.stdout.trim() ? JSON.parse(r.stdout) : null;
        song = np?.song ? { title: np.song, playing: np.state === "playing" } : null;
      } catch {}
      if (JSON.stringify(song) !== JSON.stringify(this.song)) { this.song = song; cx.notify(); }
    });
  }

  refreshReviews(cx) {
    cx.spawn(async (cx) => {
      try {
        const r = await exec("gh", ["search", "prs", "--state", "open", "--review-requested", "@me", "--json", "number", "--limit", "100"], { timeout: 60000 });
        if (r.code === 0) { this.reviews = JSON.parse(r.stdout).length; cx.notify(); }
      } catch {}
    });
  }

  refreshPlans(cx) {
    cx.spawn(async (cx) => {
      try {
        const r = await exec("plan", ["list", "--json"], { timeout: 30000 });
        if (r.code === 0) { this.plans = (JSON.parse(r.stdout).plans ?? []).filter((p) => p.status === "active").length; cx.notify(); }
      } catch {}
    });
  }

  render() {
    const t = theme();
    const space = spaces().find((s) => s.active);
    const list = agents();
    const count = (status) => list.filter((a) => a.status === status).length;
    const reviews = shared("dotfiles.reviews") ?? this.reviews;
    const plans = shared("dotfiles.plans") ?? this.plans;
    const icon = (name) => svg(`mods/workspace-chrome/${name}.svg`).size(13);
    const label = (name, text) => h_flex().gap(6).items_center().child(icon(name)).child(text);
    const chip = (id, color, text, action) => h_flex().id(id).gap(5).items_center().px(6).rounded(4).cursor_pointer()
      .hover((s) => s.bg(t.hover)).on_click(action)
      .child(div().size(6).rounded(3).bg(color)).child(div().text_color(color).child(text));
    const agentChip = (status, glyph) => count(status) > 0
      ? chip(`agents-${status}`, t[status], `${glyph} ${count(status)}`, () => run("agent.next"))
      : null;
    return h_flex().size_full().px(14).gap(14).items_center().bg(t.chrome).border_b(1).border_color(t.border).text_size(11.8).text_color(t.muted)
      .child(h_flex().gap(2).items_center().children(spaces().slice(0, 9).map((s, i) =>
        h_flex().id(`space-${s.id}`).gap(5).items_center().px(7).h(20).rounded(5).cursor_pointer()
          .bg(s.active ? t.selected : t.chrome).hover((e) => e.bg(t.hover))
          .on_click(() => run("space.select", { id: s.id }))
          .child(div().text_color(s.active ? t.accent : t.dim).font_semibold().child(`⌘${i + 1}`))
          .child(div().max_w(140).truncate().text_color(s.active ? t.foreground : t.muted).child(s.machine ? `${s.machine}/${s.name}` : s.name))
          .when(Boolean(s.status) && s.status !== "idle", (e) => e.child(div().size(6).rounded(3).bg(t[s.status] ?? t.dim))))))
      .when(Boolean(space?.branch), (el) => el.child(label("branch", space.branch)))
      .child(h_flex().gap(4).items_center()
        .child(div().text_color(t.dim).child(`${list.length} agents`))
        .children([agentChip("blocked", "⚠"), agentChip("done", "●"), agentChip("working", "◌")].filter(Boolean)))
      .when(Boolean(this.fleet), (el) => el.child(
        chip("fleet", this.fleet.attention > 0 ? t.blocked : this.fleet.busy > 0 ? t.working : t.dim,
          `fleet ${this.fleet.total}${this.fleet.attention ? ` · ${this.fleet.attention} waiting` : ""}`, () => togglePanel("fleet"))))
      .when(reviews !== null && reviews !== undefined, (el) => el.child(
        chip("reviews", reviews > 0 ? t.accent : t.dim, `${reviews} to review`, () => togglePanel("pulls"))))
      .when(plans !== null && plans !== undefined, (el) => el.child(
        chip("plans", plans > 0 ? t.ansi6 : t.dim, `${plans} active plans`, () => togglePanel("plans"))))
      .child(div().flex_1())
      .when(Boolean(this.song), (el) => el.child(
        h_flex().id("song").gap(6).items_center().px(10).h(20).rounded(10).cursor_pointer()
          .bg(this.song.playing ? t.accent : t.raised).text_color(this.song.playing ? t.accent_foreground : t.muted)
          .on_click(() => exec("nowplaying-cli", ["togglePlayPause"]))
          .child(this.song.playing ? "♪" : "⏸").child(div().max_w(320).truncate().child(this.song.title))))
      .child(div().text_color(t.foreground).child(this.clock));
  }
}
