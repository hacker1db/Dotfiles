import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { closeOverlay, exec, focused, props, run, spaces, theme } from "herdr";

const LIMIT = 2000;

export default class PdfPicker extends View {
  init(_props, cx) {
    const space = spaces().find((s) => s.active);
    this.root = focused()?.cwd || space?.folder || null;
    this.space = space?.id ?? null;
    this.files = null;
    this.query = "";
    this.sel = 0;
    this.input = InputState.new({ placeholder: "Filter PDFs" });
    this.input.on("change", (_e, cx) => { this.query = this.input.value(); this.sel = 0; cx.notify(); });
    this.input.on("submit", () => this.open(this.matches()[this.sel]));
    this.input.focus();
    cx.timer.after(300, () => this.input.focus());
    this.handle = cx.focus_handle();
    if (!this.root) { this.files = []; return; }
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: this.root });
        if (top.code === 0 && top.stdout.trim()) this.root = top.stdout.trim();
      } catch {}
      try {
        const r = await exec("fd", ["-e", "pdf", "-t", "f", "--max-results", String(LIMIT), ".", this.root], { timeout: 30000 });
        this.files = r.stdout.split("\n").filter(Boolean).map((path) => ({ path, rel: path.startsWith(`${this.root}/`) ? path.slice(this.root.length + 1) : path }));
      } catch (e) {
        this.error = String(e.message ?? e);
        this.files = [];
      }
      cx.notify();
    });
  }

  matches() {
    const words = this.query.toLowerCase().split(/\s+/).filter(Boolean);
    return (this.files ?? []).filter((f) => words.every((w) => f.rel.toLowerCase().includes(w))).slice(0, 300);
  }

  open(file) {
    if (!file) return;
    closeOverlay(props().overlay);
    run("tab.new", { ...(this.space ? { space: this.space } : {}), mod: "pdf-view", props: { path: file.path }, name: file.path.split("/").pop() });
  }

  key(e, cx) {
    const list = this.matches();
    if (e.key === "escape") closeOverlay(props().overlay);
    else if (e.key === "down") this.sel = Math.min(list.length - 1, this.sel + 1);
    else if (e.key === "up") this.sel = Math.max(0, this.sel - 1);
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  render() {
    const t = theme();
    const list = this.matches();
    return v_flex().id("pdf-picker").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .size_full().min_h(0).p(16).gap(10).bg(t.popover).text_color(t.foreground).text_size(12.5)
      .child(h_flex().items_center()
        .child(div().flex_1().text_size(15).font_semibold().child("Open a PDF"))
        .child(div().text_size(11).text_color(t.dim).child("↑↓ Enter · Esc")))
      .child(div().text_size(11.5).text_color(t.dim).truncate().child(this.root ?? "No folder"))
      .child(Input.new(this.input).h(34).px(10).rounded(8).border_1().border_color(t.accent).bg(t.background).text_size(12.8).text_color(t.foreground))
      .when(Boolean(this.error), (el) => el.child(div().text_color(t.blocked).child(this.error)))
      .child(v_flex().id("pdf-list").flex_1().min_h(0).overflow_y_scrollbar().gap(1)
        .when(this.files === null, (el) => el.child(div().py(8).text_color(t.dim).child("Looking for PDFs…")))
        .when(this.files !== null && list.length === 0, (el) => el.child(div().py(8).text_color(t.dim).child("No PDFs here")))
        .children(list.map((f, i) => {
          const parts = f.rel.split("/"), name = parts.pop();
          return h_flex().id(`pdf-${i}`).h(28).flex_none().px(8).gap(8).items_center().rounded(6).cursor_pointer()
            .when(i === this.sel, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
            .on_click(() => this.open(f))
            .child(div().flex_none().px(4).rounded(3).bg(t.blocked).text_color(t.background).text_size(9.5).font_semibold().child("PDF"))
            .child(div().flex_none().max_w(320).truncate().child(name))
            .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(parts.join("/")));
        })));
  }
}
