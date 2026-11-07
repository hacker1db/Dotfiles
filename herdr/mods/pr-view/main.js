import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, Scrollbar, TextView, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { appHome, exec, nextCommand, notify, props, readTextFile, setShared, settings, shared, theme, writeTextFile } from "herdr";
import { classifyPr } from "./tier.js";
import { overviewSections, tierBadge } from "./overview.js";
import { agentsFor, launchReview, reviewFile } from "./agents.js";

const FIELDS = "number,title,body,author,state,isDraft,baseRefName,headRefName,additions,deletions,changedFiles,reviewDecision,latestReviews,comments,statusCheckRollup,url,labels,createdAt,files";

function age(iso) {
  const minutes = Math.max(0, Math.round((Date.now() - Date.parse(iso)) / 60000));
  if (minutes < 60) return `${minutes}m`;
  if (minutes < 1440) return `${Math.round(minutes / 60)}h`;
  return `${Math.round(minutes / 1440)}d`;
}

function parseDiff(text) {
  const files = [];
  let file = null;
  for (const line of text.split("\n")) {
    const header = /^diff --git a\/(.*) b\/(.*)$/.exec(line);
    if (header) {
      file = { path: header[2], lines: [], add: 0, del: 0, started: false };
      files.push(file);
      continue;
    }
    if (!file) continue;
    if (line.startsWith("@@")) file.started = true;
    if (!file.started) {
      if (line.startsWith("Binary files")) file.lines.push(line);
      continue;
    }
    if (line.startsWith("+")) file.add++;
    if (line.startsWith("-")) file.del++;
    file.lines.push(line);
  }
  return files;
}

function diffRows(lines) {
  let old = 0, next = 0;
  return lines.map((line) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; return { kind: "@", text: line }; }
    const kind = line[0];
    if (kind === "-") return { kind, number: old++, text: line.slice(1) || " " };
    if (kind === "+") return { kind, number: next++, text: line.slice(1) || " " };
    if (kind === " ") { old++; return { kind, number: next++, text: line.slice(1) || " " }; }
    return { kind: "", text: line || " " };
  });
}

function checkState(c) {
  const result = (c.conclusion || c.state || c.status || "").toUpperCase();
  if (["SUCCESS", "NEUTRAL", "SKIPPED"].includes(result)) return "pass";
  if (["FAILURE", "ERROR", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED", "STARTUP_FAILURE"].includes(result)) return "fail";
  return "pending";
}

export default class PrView extends View {
  init(_props, cx) {
    this.url = props()?.url;
    this.pr = null;
    this.files = [];
    this.rows = [];
    this.open = null;
    this.tab = props()?.tab === "files" ? "files" : "overview";
    this.error = null;
    this.loading = false;
    this.busy = false;
    this.text = "";
    this.input = InputState.new({ placeholder: "Review summary (required to request changes)" });
    this.input.on("change", (_e, cx) => { this.text = this.input.value(); cx.notify(); });
    this.comments = [];
    this.selLine = null;
    this.lineText = "";
    this.lineInput = InputState.new({ placeholder: "Comment on this line" });
    this.lineInput.on("change", (_e, cx) => { this.lineText = this.lineInput.value(); cx.notify(); });
    this.lineInput.on("submit", (_e, cx) => this.addComment(cx));
    this.handle = cx.focus_handle();
    this.diffScroll = VirtualListScrollHandle.new();
    this.hint = false;
    cx.spawn(async (cx) => {
      for (;;) {
        if ((await nextCommand()) === "focus") { this.handle.focus(); cx.notify(); }
      }
    });

    this.agentReview = null;
    this.reviewing = null;
    this.choosing = false;
    this.load(cx);
    cx.timer.every(5000, (cx) => this.loadReview(cx));
  }

  loadReview(cx) {
    const file = reviewFile(this.url);
    if (!file) return;
    cx.spawn(async (cx) => {
      let text = null;
      try { text = await readTextFile(file); } catch {}
      if (!text || text === this.reviewText) return;
      try {
        this.agentReview = JSON.parse(text);
        this.reviewText = text;
        if (this.reviewing) notify({ title: `Agent review ready for #${this.pr?.number}`, body: this.agentReview.verdict ?? "", level: "success", timeout: 5000 });
        this.reviewing = null;
        cx.notify();
      } catch {}
    });
  }

  startReview(agentId, cx) {
    this.choosing = false;
    cx.spawn(async (cx) => {
      try {
        const agent = await launchReview(agentId, this.url, this.tier ?? { tier: "branch", reason: "unknown" }, this.pr ? `#${this.pr.number}` : "");
        this.reviewing = agent.label;
      } catch (e) {
        notify({ title: "Review agent did not start", body: String(e.message ?? e), level: "error" });
      }
      cx.notify();
    });
    cx.notify();
  }

  showFile(path, line, cx) {
    if (!this.files.some((f) => f.path === path)) return;
    this.tab = "files";
    this.pick(path);
    if (line) {
      const index = this.rows.findIndex((r) => r.kind !== "-" && r.number === line);
      if (index >= 0) {
        this.selLine = index;
        this.diffScroll?.scroll_to_item(index);
      }
    }
    cx.notify();
  }

  queueFinding(f, key, cx) {
    if (!f.file || !f.line || this.comments.some((c) => c.fromFinding === key)) return;
    const body = [f.title && `**${f.title}**`, f.detail, f.suggestion && `Suggestion: ${f.suggestion}`].filter(Boolean).join("\n\n");
    this.comments.push({ path: f.file, line: f.line, side: "RIGHT", body, fromFinding: key });
    cx.notify();
  }

  load(cx) {
    if (!this.url || this.loading) return;
    this.loading = true;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const [view, diff] = await Promise.all([
          exec("gh", ["pr", "view", this.url, "--json", FIELDS], { timeout: 60000 }),
          exec("gh", ["pr", "diff", this.url, "--color", "never"], { timeout: 120000 }),
        ]);
        if (view.code !== 0) throw new Error(view.stderr.trim() || `gh exited ${view.code}`);
        this.pr = JSON.parse(view.stdout);
        this.tier = classifyPr(this.pr.files);
        setShared("dotfiles.pr-files", { ...(shared("dotfiles.pr-files") ?? {}), [this.url]: {
          number: this.pr.number, title: this.pr.title,
          files: this.tier.files.map(({ path, additions, deletions, tier, reason }) => ({ path, additions, deletions, tier, reason })),
        } });
        this.files = diff.code === 0 ? parseDiff(diff.stdout) : [];
        if (diff.code !== 0) this.diffError = diff.stderr.trim() || "Could not load the diff";
        if (!this.files.some((f) => f.path === this.open)) this.pick(this.files[0]?.path ?? null);
        this.error = null;
      } catch (e) {
        this.error = String(e.message ?? e);
      }
      this.loading = false;
      this.loadReview(cx);
      cx.notify();
    });
  }

  pick(path) {
    this.open = path;
    this.selLine = null;
    const file = this.files.find((f) => f.path === path);
    this.rows = diffRows(file ? (file.lines.length ? file.lines : ["No text diff"]) : []);
    this.diffWidth = Math.max(300, ...this.rows.map((r) => r.text.length * 7 + 60));
  }

  anchor(row) {
    if (!row || row.number === undefined) return null;
    return { path: this.open, line: row.number, side: row.kind === "-" ? "LEFT" : "RIGHT" };
  }

  commentAt(path, line, side) {
    return this.comments.filter((c) => c.path === path && c.line === line && c.side === side);
  }

  addComment(cx) {
    const at = this.anchor(this.rows[this.selLine]);
    const body = this.lineText.trim();
    if (!at || !body) return;
    this.comments.push({ ...at, body });
    this.lineText = "";
    this.lineInput.set_value("");
    this.selLine = null;
    cx.notify();
  }

  review(kind, cx) {
    const body = this.text.trim();
    const event = { approve: "APPROVE", "request-changes": "REQUEST_CHANGES", comment: "COMMENT" }[kind];
    if (this.busy || (kind === "request-changes" && !body) || (kind === "comment" && !body && !this.comments.length)) return;
    const match = /github\.com\/([^/]+)\/([^/]+)\/pull\/(\d+)/.exec(this.url);
    if (!match) return;
    this.busy = true;
    cx.notify();
    const payload = JSON.stringify({ event, body, comments: this.comments.map(({ path, line, side, body }) => ({ path, line, side, body })) });
    const file = `${appHome()}/data/pr-review-${match[3]}.json`;
    cx.spawn(async (cx) => {
      try {
        await writeTextFile(file, payload, await readTextFile(file));
        const r = await exec("gh", ["api", `repos/${match[1]}/${match[2]}/pulls/${match[3]}/reviews`, "--method", "POST", "--input", file], { timeout: 60000 });
        exec("rm", ["-f", file]);
        if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim() || `gh exited ${r.code}`);
        const label = { APPROVE: "Approved", REQUEST_CHANGES: "Requested changes on", COMMENT: "Reviewed" }[event];
        const extra = this.comments.length ? ` with ${this.comments.length} line comment${this.comments.length === 1 ? "" : "s"}` : "";
        notify({ title: `${label} #${this.pr?.number}${extra}`, body: this.pr?.title, level: "success", timeout: 4000 });
        this.text = "";
        this.input.set_value("");
        this.comments = [];
        this.busy = false;
        this.load(cx);
      } catch (e) {
        notify({ title: "Review not submitted", body: String(e.message ?? e), level: "error" });
        this.busy = false;
      }
      cx.notify();
    });
  }

  pill(t, text, color) {
    return div().px(6).py(1).rounded(4).border_1().border_color(color).text_size(10.5).text_color(color).child(text);
  }

  header(t, pr) {
    const decision = { APPROVED: ["approved", t.done], CHANGES_REQUESTED: ["changes requested", t.blocked], REVIEW_REQUIRED: ["review required", t.working] }[pr.reviewDecision];
    const repo = this.url.replace(/^https:\/\/github\.com\//, "").replace(/\/pull\/\d+$/, "");
    return v_flex().flex_none().px(16).pt(12).pb(10).gap(6).border_b(1).border_color(t.border)
      .child(h_flex().gap(8).items_center()
        .child(div().text_color(t.accent).font_semibold().child(`#${pr.number}`))
        .when(Boolean(this.agentReview?.tier ?? this.tier?.tier), (el) => el.child(tierBadge(t, this.agentReview?.tier ?? this.tier.tier)))
        .child(div().flex_1().min_w(0).truncate().text_size(15).font_semibold().child(pr.title))
        .child(div().id("pr-agent").px(10).py(3).rounded(6).cursor_pointer().border_1().border_color(t.accent)
          .bg(this.choosing ? t.accent : t.chrome).text_color(this.choosing ? t.accent_foreground : t.accent).hover((s) => s.opacity(0.88))
          .on_click((_e, cx) => { this.choosing = !this.choosing; cx.notify(); })
          .child(this.reviewing ? `${this.reviewing} reviewing…` : "Review with agent ▾"))
        .child(div().id("pr-browser").px(8).py(2).rounded(5).cursor_pointer().text_color(t.muted).hover((s) => s.bg(t.hover))
          .on_click(() => exec("open", [pr.url])).child("Open in browser ↗"))
        .child(div().id("pr-reload").px(6).py(2).rounded(5).cursor_pointer().text_color(t.muted).hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => this.load(cx)).child(this.loading ? "…" : "↻")))
      .child(h_flex().gap(8).items_center().text_size(11.5).text_color(t.muted)
        .child(this.pill(t, pr.isDraft ? "draft" : pr.state.toLowerCase(), pr.isDraft ? t.dim : t.done))
        .when(Boolean(decision), (el) => el.child(this.pill(t, decision[0], decision[1])))
        .child(div().child(repo))
        .child(div().child(`${pr.author?.login ?? ""} · ${age(pr.createdAt)} ago`))
        .child(div().text_color(t.dim).child(`${pr.baseRefName} ← ${pr.headRefName}`))
        .child(div().flex_1())
        .child(div().text_color(t.ansi2).child(`+${pr.additions}`))
        .child(div().text_color(t.ansi1).child(`−${pr.deletions}`)))
      .when((pr.labels ?? []).length > 0, (el) => el.child(h_flex().gap(4).flex_wrap().children(pr.labels.map((l) => this.pill(t, l.name, t.muted)))))
      .when(this.choosing, (el) => el.child(this.agentChooser(t)));
  }

  agentChooser(t) {
    const agents = agentsFor(this.url);
    const allowed = agents.filter((a) => a.allowed);
    return v_flex().gap(6).mt(4).p(10).rounded(8).border_1().border_color(t.accent).bg(t.surface)
      .child(h_flex().gap(8).items_center()
        .child(div().font_semibold().text_size(12).child("Which agent should review this?"))
        .child(div().text_size(11).text_color(t.dim).child(allowed[0]?.personal ? "personal repository" : "work repository")))
      .child(h_flex().gap(6).flex_wrap().children(agents.map((a) => div().id(`agent-${a.id}`).px(10).py(5).rounded(6).text_size(12)
        .border_1().border_color(a.allowed ? t.input : t.border)
        .when(a.allowed, (e) => e.cursor_pointer().bg(t.raised).text_color(t.foreground).hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => this.startReview(a.id, cx)))
        .when(!a.allowed, (e) => e.text_color(t.dim).opacity(0.5))
        .child(a.allowed ? a.label : `${a.label} · not for this repo`))))
      .child(div().text_size(11).text_color(t.dim).child("It runs your pr-review skill in a split and writes findings here; nothing is posted to GitHub."));
  }

  tabs(t, pr) {
    const tab = (id, label) => div().id(`tab-${id}`).px(10).py(6).cursor_pointer().text_size(12)
      .border_b(2).border_color(this.tab === id ? t.accent : t.chrome).text_color(this.tab === id ? t.foreground : t.muted)
      .on_click((_e, cx) => { this.tab = id; cx.notify(); }).child(label);
    return h_flex().flex_none().px(10).gap(2).bg(t.chrome).border_b(1).border_color(t.border)
      .child(tab("overview", "Overview"))
      .child(tab("files", `Files ${pr.changedFiles}`))
      .child(div().flex_1())
      .child(div().id("key-hint").min_w(0).truncate().px(8).cursor_pointer().text_size(11).text_color(t.dim)
        .on_click((_e, cx) => { this.hint = !this.hint; cx.notify(); })
        .child(!this.hint ? "?" : this.tab === "files"
          ? "j/k line · d/u half page · g/G first/last · J/K or ]/[ file · c/⏎ comment · esc back · o/f 1/2 tab · r reload"
          : "o/f 1/2 tab · r reload · ? hide"));
  }

  block(t, id, title, meta, body) {
    return v_flex().gap(6).p(12).rounded(8).border_1().border_color(t.border).bg(t.surface)
      .child(h_flex().gap(8).text_size(11.5).child(div().font_semibold().child(title)).child(div().text_color(t.dim).child(meta)))
      .child(TextView.markdown(id, body || "_No description_").selectable(true));
  }

  scrollOverview(delta) {
    const max = Math.max(0, (this.ovContent ?? 0) - (this.ovView ?? 0));
    this.ovScroll = Math.max(0, Math.min((this.ovScroll ?? 0) + delta, max));
  }

  overview(t, pr) {
    this.scrollOverview(0);
    const view = this.ovView ?? 0, content = this.ovContent ?? 0;
    const thumb = content > view && view > 0 ? Math.max(24, (view * view) / content) : 0;
    const top = thumb ? ((view - thumb) * this.ovScroll) / (content - view) : 0;
    return div().id("pr-overview").flex_1().min_h(0).relative().overflow_hidden()
      .on_size_change((size, cx) => { if (size.height !== this.ovView) { this.ovView = size.height; cx.notify(); } })
      .on_scroll_wheel((e, cx) => { this.scrollOverview(-e.delta.y); cx.notify(); })
      .child(v_flex().id("pr-overview-content").absolute().left(0).right(0).top(-this.ovScroll).p(14).gap(12).text_size(12.5)
        .on_size_change((size, cx) => { if (size.height !== this.ovContent) { this.ovContent = size.height; cx.notify(); } })
        .children(overviewSections(this, t, pr)))
      .when(thumb > 0, (el) => el.child(div().absolute().right(2).top(top).w(4).h(thumb).rounded(2).bg(t.border)));
  }

  diffRow({ kind, number, text }, t, index) {
    const at = this.anchor({ kind, number });
    const noted = at && this.commentAt(at.path, at.line, at.side).length > 0;
    const selected = index === this.selLine;
    if (kind === "@") return div().w_full().px(12).h(20).flex_none().truncate().bg(t.raised).text_color(t.dim).child(text);
    return h_flex().w_full().h(20).flex_none().gap(10).when(kind === "+", (e) => e.bg(t.ansi2 + "18")).when(kind === "-", (e) => e.bg(t.ansi1 + "18"))
      .when(selected, (e) => e.bg(t.accent + "33"))
      .child(div().w(18).flex_none().text_center().child(noted ? "💬" : ""))
      .child(div().w(36).flex_none().text_right().text_color(t.dim).child(number === undefined ? "" : String(number)))
      .child(div().w(10).flex_none().text_color(kind === "+" ? t.ansi2 : kind === "-" ? t.ansi1 : t.dim).child(kind === " " ? "" : kind))
      .child(div().flex_1().min_w(0).child(text));
  }

  composer(t) {
    const at = this.anchor(this.rows[this.selLine]);
    const notes = this.comments.filter((c) => c.path === this.open);
    return v_flex().flex_none().gap(6).px(12).py(8).border_t(1).border_color(t.border).bg(t.surface).text_size(12)
      .when(Boolean(at), (el) => el
        .child(div().text_color(t.muted).child(`${at.path}:${at.line} (${at.side === "LEFT" ? "old" : "new"} side)`))
        .child(h_flex().gap(8)
          .child(div().id("line-comment").flex_1().min_w(0).h(30).px(10).flex().items_center().rounded(7).border_1().border_color(t.accent).bg(t.background)
            .cursor_text().on_mouse_down("left", (_e, cx) => cx.stop_propagation())
            .on_key_down((e, cx) => { if (e.key !== "escape") return; this.handle.focus(); cx.stop_propagation(); cx.notify(); })
            .child(Input.new(this.lineInput).h_full().text_size(12).text_color(t.foreground)))
          .child(div().id("line-add").h(30).px(12).flex().items_center().rounded(7).cursor_pointer().bg(t.accent).text_color(t.accent_foreground)
            .on_click((_e, cx) => this.addComment(cx)).child("Add comment"))
          .child(div().id("line-cancel").h(30).px(10).flex().items_center().rounded(7).cursor_pointer().text_color(t.muted).hover((s) => s.bg(t.hover))
            .on_click((_e, cx) => { this.selLine = null; cx.notify(); }).child("Cancel"))))
      .when(!at, (el) => el.child(div().text_color(t.dim).child("Click a line to comment on it")))
      .children(notes.map((c, i) => h_flex().id(`note-${c.path}-${c.side}-${c.line}-${i}`).gap(8).items_center().text_size(11.5)
        .child(div().flex_none().text_color(t.accent).child(`L${c.line}${c.side === "LEFT" ? " (old)" : ""}`))
        .child(div().flex_1().min_w(0).truncate().child(c.body))
        .child(div().id(`note-rm-${i}`).px(6).cursor_pointer().text_color(t.dim).hover((s) => s.text_color(t.blocked))
          .on_click((_e, cx) => { this.comments.splice(this.comments.indexOf(c), 1); cx.notify(); }).child("✕"))));
  }

  filesView(t) {
    return v_flex().flex_1().min_h(0).child(this.filesPane(t)).child(this.composer(t));
  }

  filesPane(t) {
    return h_flex().flex_1().min_h(0)
      .child(v_flex().id("pr-files").w(280).flex_none().h_full().overflow_y_scrollbar().p(6).border_r(1).border_color(t.border)
        .when(Boolean(this.diffError), (el) => el.child(div().p(8).text_size(11).text_color(t.blocked).child(this.diffError)))
        .children(this.files.map((f) => {
          const parts = f.path.split("/"), name = parts.pop();
          return h_flex().id(`file-${f.path}`).h(28).flex_none().px(8).gap(6).items_center().rounded(6).cursor_pointer().text_size(12)
            .when(this.open === f.path, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
            .on_click((_e, cx) => { this.pickFile(f.path); cx.notify(); })
            .child(h_flex().flex_1().min_w(0).child(div().text_color(t.dim).truncate().child(parts.length ? parts.join("/") + "/" : "")).child(div().flex_none().max_w(200).truncate().child(name)))
            .when(this.comments.some((c) => c.path === f.path), (e) => e.child(div().text_size(10.5).child("💬")))
            .when(f.add > 0, (e) => e.child(div().text_size(10.5).text_color(t.ansi2).child(`+${f.add}`)))
            .when(f.del > 0, (e) => e.child(div().text_size(10.5).text_color(t.ansi1).child(`−${f.del}`)));
        })))
      .child(div().flex_1().min_w(0).h_full().relative().font_family(settings().font_family ?? "JetBrains Mono").text_size(11.5).bg(t.background)
        .child(div().id("pr-diff-x").size_full().overflow_x_scrollbar()
          .child(div().w_full().min_w(this.diffWidth ?? 300).h_full().child(v_virtual_list("pr-diff", this.rows.length, 20, (i) => String(i),
            (range) => this.rows.slice(range.start, range.end).map((row, k) => this.diffRow(row, t, range.start + k)))
            .on_item_click((key, cx) => {
              const index = Number(key);
              if (!this.anchor(this.rows[index])) return;
              this.selLine = index;
              this.lineInput.focus();
              cx.notify();
            }).track_scroll(this.diffScroll).size_full())))
        .child(Scrollbar.vertical("pr-diff").viewport_from_layout().absolute().inset_0()));
  }

  reviewBar(t) {
    const hasBody = Boolean(this.text.trim());
    const pending = this.comments.length;
    const button = (id, label, enabled, color, action) => div().id(id).h(32).px(12).flex().flex_none().items_center().rounded(8).text_size(12)
      .border_1().border_color(enabled ? color : t.border).bg(enabled ? color : t.raised).text_color(enabled ? t.background : t.dim)
      .when(enabled, (e) => e.cursor_pointer().hover((s) => s.opacity(0.88))).on_click(action).child(label);
    return h_flex().flex_none().p(10).gap(8).items_center().border_t(1).border_color(t.border).bg(t.chrome)
      .child(div().id("review-body").flex_1().min_w(0).h(32).px(10).flex().items_center().rounded(8).border_1().border_color(t.input).bg(t.background)
        .cursor_text().on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .child(Input.new(this.input).h_full().text_size(12).text_color(t.foreground)))
      .when(pending > 0, (el) => el.child(div().flex_none().text_size(11.5).text_color(t.accent).child(`${pending} line comment${pending === 1 ? "" : "s"}`)))
      .child(button("review-comment", "Comment", (hasBody || pending > 0) && !this.busy, t.accent, (_e, cx) => this.review("comment", cx)))
      .child(button("review-changes", "Request changes", hasBody && !this.busy, t.blocked, (_e, cx) => this.review("request-changes", cx)))
      .child(button("review-approve", this.busy ? "Submitting…" : "Approve", !this.busy, t.done, (_e, cx) => this.review("approve", cx)));
  }

  key(e, cx) {
    const m = e.modifiers;
    if (m.control || m.platform || m.alt || !this.handle.is_focused()) return;
    const c = e.key_char;
    const k = c && c.length === 1 && c.trim() ? c : m.shift && e.key.length === 1 ? e.key.toUpperCase() : e.key;
    const files = this.tab === "files";
    const i = this.files.findIndex((f) => f.path === this.open);
    const half = 15;
    if (k === "o" || k === "1") this.tab = "overview";
    else if (k === "f" || k === "2") this.tab = "files";
    else if (k === "?") this.hint = !this.hint;
    else if (k === "r") this.load(cx);
    else if (files && (k === "J" || k === "]")) { if (i < this.files.length - 1) this.pickFile(this.files[i + 1].path); }
    else if (files && (k === "K" || k === "[")) { if (i > 0) this.pickFile(this.files[i - 1].path); }
    else if (files && (k === "j" || k === "down")) this.moveLine(1);
    else if (files && (k === "k" || k === "up")) this.moveLine(-1);
    else if (files && k === "d") this.moveLine(half);
    else if (files && k === "u") this.moveLine(-half);
    else if (files && k === "g") this.moveLine(-Infinity);
    else if (files && k === "G") this.moveLine(Infinity);
    else if (!files && (k === "j" || k === "down")) this.scrollOverview(60);
    else if (!files && (k === "k" || k === "up")) this.scrollOverview(-60);
    else if (!files && k === "d") this.scrollOverview((this.ovView ?? 600) / 2);
    else if (!files && k === "u") this.scrollOverview(-(this.ovView ?? 600) / 2);
    else if (!files && k === "g") this.scrollOverview(-Infinity);
    else if (!files && k === "G") this.scrollOverview(Infinity);
    else if (files && (k === "c" || k === "enter")) {
      if (!this.anchor(this.rows[this.selLine])) this.moveLine(0);
      if (this.anchor(this.rows[this.selLine])) this.lineInput.focus();
    }
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  pickFile(path) {
    this.pick(path);
    this.diffScroll.scroll_to_item(0);
  }

  moveLine(delta) {
    const lines = [];
    this.rows.forEach((r, i) => { if (this.anchor(r)) lines.push(i); });
    if (!lines.length) return;
    const at = lines.indexOf(this.selLine);
    const next = at < 0 ? (delta === Infinity ? lines.length - 1 : 0) : Math.max(0, Math.min(lines.length - 1, at + delta));
    this.selLine = lines[next];
    const last = this.rows.length - 1;
    const edge = next === 0 ? 0 : next === lines.length - 1 ? last : Math.max(0, Math.min(last, this.selLine + (delta < 0 ? -3 : 3)));
    this.diffScroll.scroll_to_item(edge);
  }

  render() {
    const request = shared("dotfiles.pr-open");
    if (request && request.url === this.url && request.at !== this.handledOpen && this.files.some((f) => f.path === request.path)) {
      this.handledOpen = request.at;
      this.tab = "files";
      this.pick(request.path);
      this.diffScroll?.scroll_to_item(0);
    }
    const t = theme();
    const pr = this.pr;
    const root = v_flex().id("root").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx)).size_full().min_h(0).bg(t.background).text_color(t.foreground).text_size(13);
    if (!this.url) return root.child(div().p(16).text_color(t.dim).child("No pull request given"));
    if (!pr) return root.child(div().p(16).text_color(this.error ? t.blocked : t.dim).child(this.error ?? "Loading pull request…"));
    return root
      .child(this.header(t, pr))
      .child(this.tabs(t, pr))
      .when(Boolean(this.error), (el) => el.child(div().px(16).py(4).text_size(11).text_color(t.blocked).child(this.error)))
      .child(this.tab === "files" ? this.filesView(t) : this.overview(t, pr))
      .child(this.reviewBar(t));
  }
}
