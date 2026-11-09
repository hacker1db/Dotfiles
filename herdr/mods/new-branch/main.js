import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { appHome, closeOverlay, exec, focused, notify, props, run, spaces, theme } from "herdr";

const TYPES = ["feat", "fix", "chore", "docs", "refactor", "perf", "test"];
const RESOLVE_BIN = 'cd -P "$1" && cd ../../.. && printf %s "$PWD/bin/wt-new"';

function slug(text) {
  return text.trim().toLowerCase().replace(/[^a-z0-9/._-]+/g, "-").replace(/-+/g, "-").replace(/^[-/.]+|[-/.]+$/g, "");
}

export default class NewBranch extends View {
  init(_props, cx) {
    this.type = "feat";
    this.text = "";
    this.error = null;
    this.busy = false;
    const space = spaces().find((s) => s.active);
    this.cwd = focused()?.cwd || space?.folder || null;
    this.remote = Boolean(space?.machine);
    this.repo = null;
    this.input = InputState.new({ value: "", placeholder: "short-description" });
    this.input.on("change", (_e, cx) => { this.text = this.input.value(); this.error = null; cx.notify(); });
    this.input.on("submit", (_e, cx) => this.submit(cx));
    this.input.focus();
    cx.timer.after(400, () => this.input.focus());
    this.handle = cx.focus_handle();
    if (this.cwd && !this.remote) {
      cx.spawn(async (cx) => {
        try {
          const r = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: this.cwd });
          this.repo = r.code === 0 ? r.stdout.trim() : null;
        } catch {}
        if (!this.repo) this.error = "The focused pane is not in a git repository.";
        cx.notify();
      });
    }
  }

  branch() {
    const name = slug(this.text);
    if (!name) return "";
    return name.includes("/") ? name : `${this.type}/${name}`;
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  submit(cx) {
    const branch = this.branch();
    if (this.busy || !branch || !this.repo) return;
    this.busy = true;
    this.error = null;
    cx.notify();
    const repo = this.repo;
    cx.spawn(async (cx) => {
      try {
        const bin = await exec("/bin/sh", ["-c", RESOLVE_BIN, "sh", `${appHome()}/mods/new-branch`]);
        if (bin.code !== 0) throw new Error("Could not find wt-new in the dotfiles checkout.");
        const r = await exec(bin.stdout, ["--json", branch], { cwd: repo, timeout: 180000 });
        if (r.code !== 0) throw new Error(r.stderr.trim().split("\n").slice(-3).join("\n") || `wt-new exited ${r.code}`);
        const out = JSON.parse(r.stdout.trim().split("\n").pop());
        run("space.new", { folder: out.path });
        const copied = out.copied ?? [];
        notify({
          title: `Worktree ${out.branch} ready`,
          body: copied.length ? `Copied ${copied.join(", ")}` : "No ignored .env files to copy",
          level: "success",
          timeout: 5000,
        });
        this.dismiss();
      } catch (e) {
        this.busy = false;
        this.error = String(e.message ?? e);
        cx.notify();
      }
    });
  }

  key(e, cx) {
    if (e.key === "escape") { this.dismiss(); cx.stop_propagation(); return; }
    if (e.key === "tab" && !this.busy) {
      const i = TYPES.indexOf(this.type);
      this.type = TYPES[(i + (e.modifiers.shift ? TYPES.length - 1 : 1)) % TYPES.length];
      cx.stop_propagation();
      cx.notify();
    }
  }

  render() {
    const t = theme();
    const branch = this.branch();
    const ready = Boolean(branch && this.repo && !this.busy);
    const chip = (type) => div().id(`type-${type}`).px(9).py(3).rounded(6).cursor_pointer().text_size(11.5)
      .border_1().border_color(this.type === type ? t.accent : t.input)
      .bg(this.type === type ? t.selected : t.raised).text_color(this.type === type ? t.foreground : t.muted)
      .on_click((_e, cx) => { this.type = type; cx.notify(); this.input.focus(); }).child(type);
    const button = (id, text, primary, action) => h_flex().id(id).h(32).px(14).items_center().rounded(8)
      .border_1().border_color(primary ? t.solid : t.input).bg(primary ? t.solid : t.raised)
      .text_color(primary ? t.solid_foreground : t.foreground).text_size(12.5).font_medium().cursor_pointer()
      .when(primary && !ready, (el) => el.opacity(0.5))
      .hover((s) => s.opacity(0.88)).on_click(action).child(text);
    return v_flex().id("new-branch").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .w_full().min_h(0).p(18).gap(10).bg(t.popover).text_color(t.foreground)
      .child(h_flex().items_center()
        .child(div().flex_1().text_size(15).font_semibold().child("New branch worktree"))
        .child(div().text_size(11).text_color(t.dim).child("Tab type · Esc")))
      .child(div().text_size(11.5).text_color(t.dim).truncate().child(this.repo ?? this.cwd ?? "No folder"))
      .child(h_flex().gap(6).flex_wrap().children(TYPES.map(chip)))
      .child(Input.new(this.input).h(36).px(10).rounded(9).border_1().border_color(t.accent).bg(t.background).text_size(12.8).text_color(t.foreground))
      .child(div().text_size(11.5).text_color(branch ? t.muted : t.dim)
        .child(branch ? `wt switch --create ${branch}, then copy ignored .env files` : "Type a name; include a / to set the full branch"))
      .when(Boolean(this.error), (el) => el.child(div().text_size(11.5).text_color(t.blocked).child(this.error)))
      .child(h_flex().pt(6).gap(8).justify_end()
        .child(button("nb-cancel", "Cancel", false, () => this.dismiss()))
        .child(button("nb-create", this.busy ? "Creating…" : "Create", true, (_e, cx) => this.submit(cx))));
  }
}
