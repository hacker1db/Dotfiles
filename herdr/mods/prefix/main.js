import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { appHome, closeOverlay, exec, focused, hc, layout, nextCommand, notify, openOverlay, panes, props, run, shared, theme } from "herdr";

const REPEAT_MS = 500;
const RESOLVE_BIN = 'cd -P "$1" && cd ../../.. && printf %s "$PWD/bin/herdr-fzf-url"';

const BINDINGS = [
  ["c", "New tab", "tab.new"],
  ["N", "New tab", "tab.new"],
  ["\\", "Split right", "pane.split", { direction: "right" }],
  ["|", "Split right", "pane.split", { direction: "right" }],
  ["-", "Split down", "pane.split", { direction: "down" }],
  ["x", "Close pane", "pane.close"],
  ["&", "Close tab", "tab.close"],
  ["h", "Focus left", "pane.go", { direction: "left" }],
  ["j", "Focus down", "pane.go", { direction: "down" }],
  ["k", "Focus up", "pane.go", { direction: "up" }],
  ["l", "Focus right", "pane.go", { direction: "right" }],
  ["left", "Focus left", "pane.go", { direction: "left" }],
  ["down", "Focus down", "pane.go", { direction: "down" }],
  ["up", "Focus up", "pane.go", { direction: "up" }],
  ["right", "Focus right", "pane.go", { direction: "right" }],
  ["ctrl-h", "Previous tab", "tab.prev", {}, true],
  ["ctrl-l", "Next tab", "tab.next", {}, true],
  ["ctrl-a", "Next pane", "@next-pane"],
  ["M", "Zoom pane", "pane.zoom"],
  ["z", "Zoom pane", "pane.zoom"],
  ["n", "Next agent", "agent.next"],
  ["f", "Fleet agents", "@panel", "fleet"],
  ["O", "Fleet dashboard", "@popup", ["fleet"]],
  ["b", "Toggle sidebar", "layout.toggle", { id: "sidebar" }],
  ["V", "Open a PDF", "mod.open", { name: "pdf-picker" }],
  ["o", "Find space", "mod.open", { name: "picker" }],
  ["s", "Find space", "mod.open", { name: "picker" }],
  ["J", "Next space", "space.next", {}, true],
  ["K", "Previous space", "space.prev", {}, true],
  [",", "Rename tab", "tab.rename"],
  ["$", "Rename space", "space.rename"],
  ["p", "Paste", "terminal.paste"],
  ["g", "lazygit", "@popup", ["lazygit"]],
  ["G", "gh dash", "@popup", ["gh", "dash"]],
  ["u", "Open a URL", "@urls"],
  ["w", "New branch worktree", "@worktree"],
  ["W", "New branch worktree", "@worktree"],
  ["P", "Pull requests", "@panel", "pulls"],
  ["T", "Plans", "@panel", "plans"],
  ["F", "Files", "@panel", "files"],
  ["C", "Changes", "@panel", "changes"],
  ["d", "Minimize window", "window.minimize"],
  ["a", "Send ctrl-a", "@send-prefix"],
  ...Array.from({ length: 10 }, (_, i) => [String(i), `Tab ${i === 0 ? 10 : i}`, "tab.select", { index: i === 0 ? 10 : i }]),
];

function findNode(tree, id) {
  if (!tree || typeof tree !== "object") return null;
  if (tree.id === id) return tree;
  for (const child of tree.children ?? []) {
    const found = findNode(child, id);
    if (found) return found;
  }
  return null;
}

function togglePanel(child) {
  if (child === "changes" && shared("dotfiles.activePr")) child = "pr-changes";
  const tree = layout();
  const panel = findNode(tree, "panel");
  const stack = findNode(tree, "panel-body");
  if (panel && !panel.hidden && stack?.active === child) {
    run("layout.hide", { id: "panel" });
    return;
  }
  run("layout.select", { stack: "panel-body", child });
  run("layout.show", { id: "panel" });
}

function nextPane() {
  const f = focused();
  if (!f) return;
  const list = panes().filter((p) => p.tab === f.tab);
  if (list.length < 2) return;
  const i = list.findIndex((p) => p.focused);
  run("pane.focus", { pane: list[(i + 1) % list.length].pane });
}

function forwardKey(e, key) {
  if (["enter", "tab", "backspace", "left", "right", "up", "down", "space"].includes(e.key)) return e.key;
  if (key === " ") return "space";
  if (/^[A-Z]$/.test(key)) return `shift+${key.toLowerCase()}`;
  if (key.length === 1 && "abcdefghijklmnopqrstuvwxyz0123456789`\\[],=-.';/".includes(key)) return key === "\\" ? "backslash" : key;
  return null;
}

export default class Prefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.repeat = false;
    this.generation = 0;
    this.all = false;
    this.busy = false;
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "next-pane") {
          nextPane();
          this.dismiss();
        }
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  send(key, cx) {
    this.generation++;
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    const pending = hc(["keys", terminal, key]);
    cx.spawn(async () => {
      const result = await pending;
      if (result.code !== 0) console.log(`prefix: ${result.stderr}`);
    });
    this.dismiss();
  }

  popup(argv, cx) {
    this.busy = true;
    cx.notify();
    const cwd = focused()?.cwd;
    const args = ["run", "--json", "--bg", "--rm", "--no-parent", ...(cwd ? ["--cwd", cwd] : []), "--", ...argv];
    const pending = hc(args);
    cx.spawn(async () => {
      const result = await pending;
      let address = null;
      try { address = JSON.parse(result.stdout).address; } catch {}
      if (result.code !== 0 || !address) {
        notify({ title: `${argv.join(" ")} did not start`, body: result.stderr.trim(), level: "error" });
      } else {
        openOverlay({ kind: "dialog", width: 0.8, height: 0.8, layout: { type: "block", content: { terminal: address } } });
      }
      this.dismiss();
    });
  }

  urls(cx) {
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    this.busy = true;
    cx.notify();
    cx.spawn(async () => {
      const bin = await exec("/bin/sh", ["-c", RESOLVE_BIN, "sh", `${appHome()}/mods/prefix`]);
      if (bin.code !== 0) {
        notify({ title: "Could not find herdr-fzf-url", body: bin.stderr.trim(), level: "error" });
        return this.dismiss();
      }
      this.popup([bin.stdout, terminal], cx);
    });
  }

  act(binding, cx) {
    const [, , command, args = {}, repeatable = false] = binding;
    switch (command) {
      case "@next-pane": nextPane(); return this.dismiss();
      case "@send-prefix": return this.send("ctrl+a", cx);
      case "@panel": this.dismiss(); return togglePanel(args);
      case "@worktree": this.dismiss(); return run("mod.open", { name: "new-branch" });
      case "@popup": return this.popup(args, cx);
      case "@urls": return this.urls(cx);
    }
    if (!repeatable) this.dismiss();
    run(command, args);
    if (repeatable) {
      this.repeat = true;
      const generation = ++this.generation;
      cx.timer.after(REPEAT_MS, () => {
        if (this.generation === generation) this.dismiss();
      });
      cx.notify();
    }
  }

  key(e, cx) {
    cx.stop_propagation();
    if (this.busy) return;
    const m = e.modifiers;
    if (e.key === "escape") return this.dismiss();
    const plain = !m.control && !m.alt && !m.platform;
    let key;
    if (plain) key = e.key_char ?? (m.shift && e.key.length === 1 ? e.key.toUpperCase() : e.key);
    else if (m.control && !m.alt && !m.platform) key = `ctrl-${e.key}`;
    else return this.dismiss();
    if (plain && key === "?") {
      this.all = !this.all;
      this.repeat = false;
      this.generation++;
      cx.notify();
      return;
    }
    const binding = BINDINGS.find((b) => b[0] === key);
    if (binding) return this.act(binding, cx);
    const forwarded = this.repeat && plain && forwardKey(e, key);
    if (forwarded) return this.send(forwarded, cx);
    this.dismiss();
  }

  render() {
    const t = theme();
    const hidden = (key) => ["left", "right", "up", "down", "N", "|", "W", "s", "z"].includes(key) || /^\d$/.test(key);
    const rows = this.all ? BINDINGS : BINDINGS.filter(([key]) => !hidden(key));
    const heading = this.busy ? "Starting…" : this.repeat ? `Repeat · ${REPEAT_MS} ms` : "Ctrl+A · waiting for a key";
    return v_flex().id("prefix").track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .p(14).gap(8).bg(t.popover).text_color(t.foreground).text_size(12)
      .child(h_flex().justify_between().child(div().font_semibold().child(heading))
        .child(div().text_color(t.muted).child("Esc cancel · a send ^A")))
      .child(v_flex().h(340).min_h(0).overflow_y_scrollbar().children(rows.map(([key, label, , , repeatable]) =>
        h_flex().h(20).flex_none().items_center().gap(12).child(div().w(52).text_color(t.accent).child(key))
          .child(div().flex_1().child(label)).child(div().text_color(t.dim).child(repeatable ? "repeat" : "")))))
      .child(div().text_color(t.muted).child("0–9 tabs · ^A^A next pane · ? all bindings"));
  }
}
