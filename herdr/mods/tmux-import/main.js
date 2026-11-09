import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { appHome, closeOverlay, exec, notify, props, theme } from "herdr";

const RESOLVE_ROOT = 'cd -P "$1" && cd ../../.. && printf %s "$PWD"';

export default class TmuxImport extends View {
  init(_props, cx) {
    this.sessions = null;
    this.error = null;
    this.busy = null;
    this.confirm = null;
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.spawn(async (cx) => {
      try {
        const root = await exec("/bin/sh", ["-c", RESOLVE_ROOT, "sh", `${appHome()}/mods/tmux-import`]);
        if (root.code !== 0) throw new Error("Could not find the dotfiles checkout");
        this.bin = `${root.stdout}/bin/tmux-to-herdr`;
        const r = await exec(this.bin, ["--list"], { timeout: 30000 });
        if (r.code !== 0) throw new Error(r.stderr.trim() || "tmux is not running");
        this.sessions = JSON.parse(r.stdout);
      } catch (e) {
        this.error = String(e.message ?? e);
        this.sessions = [];
      }
      cx.notify();
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  run(session, replace, cx) {
    if (this.busy) return;
    this.busy = session.name;
    this.confirm = null;
    this.error = null;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const r = await exec(this.bin, [...(replace ? ["--replace"] : []), session.name], { timeout: 300000 });
        if (r.code !== 0) throw new Error(r.stderr.trim().split("\n").slice(-2).join("\n") || `exited ${r.code}`);
        notify({ title: `${session.name} is in Herdr`, body: r.stdout.trim().split("\n").slice(-1)[0], level: "success", timeout: 5000 });
        this.dismiss();
      } catch (e) {
        this.error = String(e.message ?? e);
        this.busy = null;
        cx.notify();
      }
    });
  }

  render() {
    const t = theme();
    const button = (id, label, primary, action) => div().id(id).h(28).px(10).flex().flex_none().items_center().rounded(7).text_size(12)
      .border_1().border_color(primary ? t.solid : t.input).bg(primary ? t.solid : t.raised)
      .text_color(primary ? t.solid_foreground : t.foreground)
      .when(!this.busy, (e) => e.cursor_pointer().hover((s) => s.opacity(0.88)))
      .on_click(action).child(label);
    const row = (s) => {
      const confirming = this.confirm === s.name;
      return h_flex().id(`session-${s.name}`).w_full().min_w(0).px(10).py(8).gap(10).items_center().rounded(8)
        .when(confirming, (e) => e.bg(t.raised))
        .child(v_flex().flex_1().min_w(0).gap(2)
          .child(h_flex().gap(6).items_center().child(div().truncate().font_medium().child(s.name))
            .when(s.attached, (e) => e.child(div().text_size(10.5).text_color(t.done).child("attached"))))
          .child(div().text_size(11).text_color(t.dim).child(
            confirming ? "Ends the tmux session; agents resume with --continue in Herdr" : `${s.windows} windows · ${s.panes} panes`)))
        .when(this.busy === s.name, (e) => e.child(div().text_size(11.5).text_color(t.muted).child("Moving…")))
        .when(!this.busy && !confirming, (e) => e
          .child(button(`copy-${s.name}`, "Copy", false, (_e, cx) => this.run(s, false, cx)))
          .child(button(`move-${s.name}`, "Move", true, (_e, cx) => { this.confirm = s.name; cx.notify(); })))
        .when(!this.busy && confirming, (e) => e
          .child(button(`cancel-${s.name}`, "Cancel", false, (_e, cx) => { this.confirm = null; cx.notify(); }))
          .child(button(`confirm-${s.name}`, "Move it", true, (_e, cx) => this.run(s, true, cx))));
    };
    return v_flex().id("tmux-import").track_focus(this.handle)
      .on_key_down((e, cx) => { if (e.key === "escape") { this.dismiss(); cx.stop_propagation(); } })
      .size_full().min_h(0).p(18).gap(10).bg(t.popover).text_color(t.foreground).text_size(12.5)
      .child(h_flex().items_center()
        .child(div().flex_1().text_size(15).font_semibold().child("Bring tmux into Herdr"))
        .child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(div().text_size(11.5).text_color(t.dim).child("Each session becomes a space, mirrored back to tmux. Copy keeps the original session; Move replaces it."))
      .when(Boolean(this.error), (el) => el.child(div().text_size(11.5).text_color(t.blocked).child(this.error)))
      .child(v_flex().id("sessions").flex_1().min_h(0).overflow_y_scrollbar().gap(2)
        .when(this.sessions === null, (el) => el.child(div().py(8).text_color(t.dim).child("Reading tmux…")))
        .when(this.sessions !== null && this.sessions.length === 0 && !this.error, (el) => el.child(div().py(8).text_color(t.dim).child("No tmux sessions to import")))
        .children((this.sessions ?? []).map(row)));
  }
}
