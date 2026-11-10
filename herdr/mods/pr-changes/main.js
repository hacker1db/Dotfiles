import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { nextCommand, setShared, shared, theme } from "herdr";

const ICON = { trunk: "🌳", branch: "🌿", leaf: "🍃" };

export default class PrChanges extends View {
  init(_props, cx) {
    this.sel = 0;
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      for (;;) {
        if ((await nextCommand()) === "focus") { this.handle.focus(); cx.notify(); }
      }
    });
  }

  current() {
    const url = shared("dotfiles.activePr");
    const pr = url ? (shared("dotfiles.pr-files") ?? {})[url] : null;
    return { url, pr, files: pr?.files ?? [] };
  }

  open(url, path) {
    setShared("dotfiles.pr-open", { url, path, at: Date.now() });
  }

  key(e, cx) {
    const m = e.modifiers;
    if (m.control || m.platform || m.alt || !this.handle.is_focused()) return;
    const { url, files } = this.current();
    const k = e.key_char && e.key_char.length === 1 && e.key_char.trim() ? e.key_char : e.key;
    if (k === "j" || k === "down") this.sel = Math.min(files.length - 1, this.sel + 1);
    else if (k === "k" || k === "up") this.sel = Math.max(0, this.sel - 1);
    else if (k === "g") this.sel = 0;
    else if (k === "G") this.sel = files.length - 1;
    else if (k === "enter" && files[this.sel]) this.open(url, files[this.sel].path);
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  render() {
    const t = theme();
    const { url, pr, files } = this.current();
    const color = { trunk: t.ansi13 ?? t.accent, branch: t.ansi2 ?? t.done, leaf: t.ansi6 ?? t.working };
    const add = files.reduce((n, f) => n + (f.additions ?? 0), 0);
    const del = files.reduce((n, f) => n + (f.deletions ?? 0), 0);
    const focusedView = this.handle.is_focused();
    return v_flex().id("root").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .size_full().bg(t.surface).text_size(12.5).text_color(t.foreground)
      .child(h_flex().h(40).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Changes"))
        .when(Boolean(pr), (el) => el.child(div().flex_1().min_w(0).truncate().text_color(t.muted).child(`#${pr.number} ${pr.title ?? ""}`)))
        .when(!pr, (el) => el.child(div().flex_1()))
        .when(files.length > 0, (el) => el
          .child(div().flex_none().text_size(11).text_color(t.dim).child(`${files.length} files`))
          .child(div().flex_none().text_size(11).text_color(t.ansi2).child(`+${add}`))
          .child(div().flex_none().text_size(11).text_color(t.ansi1).child(`−${del}`))))
      .child(v_flex().id("pr-changes-list").flex_1().min_h(0).overflow_y_scrollbar().p(6)
        .when(!url, (el) => el.child(div().p(8).text_color(t.dim).child("No pull request in this tab")))
        .when(Boolean(url) && !pr, (el) => el.child(div().p(8).text_color(t.dim).child("Loading the pull request…")))
        .children(files.map((f, i) => {
          const parts = f.path.split("/"), name = parts.pop();
          return h_flex().id(`prc-${f.path}`).h(30).flex_none().px(8).gap(8).items_center().rounded(7).cursor_pointer()
            .when(focusedView && i === this.sel, (e) => e.bg(t.selected))
            .hover((s) => s.bg(t.hover))
            .on_click(() => { this.sel = i; this.open(url, f.path); })
            .child(div().w(16).flex_none().text_color(color[f.tier] ?? t.dim).child(ICON[f.tier] ?? ""))
            .child(h_flex().flex_1().min_w(0)
              .child(div().text_color(t.dim).truncate().child(parts.length ? parts.join("/") + "/" : ""))
              .child(div().flex_none().max_w(220).truncate().child(name)))
            .when((f.additions ?? 0) > 0, (e) => e.child(div().flex_none().text_size(11).text_color(t.ansi2).child(`+${f.additions}`)))
            .when((f.deletions ?? 0) > 0, (e) => e.child(div().flex_none().text_size(11).text_color(t.ansi1).child(`−${f.deletions}`)));
        })));
  }
}
