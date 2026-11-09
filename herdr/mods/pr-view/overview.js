import { div } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { exec } from "herdr";
import { TIERS, TIER_DEFS, TIER_ICON } from "./tier.js";

// Check and status links are set by whoever reports the check, so only open https URLs,
// and pass "--" so a value can never be read as an `open` option.
export function safeUrl(url) {
  return typeof url === "string" && /^https:\/\/[^\s]+$/i.test(url) ? url : null;
}

export function openUrl(url) {
  const safe = safeUrl(url);
  if (safe) exec("open", ["--", safe]);
}

const SEVERITIES = ["critical", "high", "medium", "low", "info"];

function age(iso) {
  const minutes = Math.max(0, Math.round((Date.now() - Date.parse(iso)) / 60000));
  if (minutes < 60) return `${minutes}m`;
  if (minutes < 1440) return `${Math.round(minutes / 60)}h`;
  return `${Math.round(minutes / 1440)}d`;
}

function checkState(c) {
  const result = (c.conclusion || c.state || c.status || "").toUpperCase();
  if (["SUCCESS", "NEUTRAL", "SKIPPED"].includes(result)) return "pass";
  if (["FAILURE", "ERROR", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED", "STARTUP_FAILURE"].includes(result)) return "fail";
  return "pending";
}

export function tierColor(t, tier) {
  return { trunk: t.ansi13 ?? t.accent, branch: t.ansi2 ?? t.done, leaf: t.ansi6 ?? t.working }[tier] ?? t.dim;
}

export function severityColor(t, severity) {
  return { critical: t.ansi9 ?? t.blocked, high: t.blocked, medium: t.ansi3 ?? t.working, low: t.working, info: t.dim }[severity] ?? t.dim;
}

export function tierBadge(t, tier, small = false) {
  const color = tierColor(t, tier);
  return h_flex().flex_none().gap(4).items_center().px(small ? 5 : 7).py(small ? 0 : 2).rounded(5)
    .border_1().border_color(color).text_color(color).text_size(small ? 10.5 : 11.5).font_semibold()
    .child(TIER_ICON[tier] ?? "").child(tier ?? "?");
}

function pill(t, text, color) {
  return div().flex_none().px(6).py(1).rounded(4).border_1().border_color(color).text_size(10.5).text_color(color).child(text);
}

function card(t, title, meta, ...children) {
  return v_flex().gap(8).p(14).rounded(10).border_1().border_color(t.border).bg(t.surface)
    .child(h_flex().gap(8).items_center()
      .child(div().font_semibold().text_size(12.5).child(title))
      .when(Boolean(meta), (e) => e.child(div().text_size(11.5).text_color(t.dim).child(meta))))
    .children(children);
}

function kpi(t, value, label, color) {
  return v_flex().flex_1().min_w(90).gap(2).p(10).rounded(8).bg(t.background).border_1().border_color(t.border)
    .child(div().text_size(18).font_semibold().text_color(color ?? t.foreground).child(String(value)))
    .child(div().text_size(11).text_color(t.dim).child(label));
}

function sortFindings(list) {
  const rank = (f) => (f.severity === "critical" ? -1 : 0) * 100 + TIERS.indexOf(f.tier ?? "branch") * 10 + SEVERITIES.indexOf(f.severity ?? "info");
  return [...list].sort((a, b) => rank(a) - rank(b));
}

function headline(view, t, pr) {
  const review = view.agentReview;
  const tier = review?.tier ? { tier: review.tier, reason: review.tier_reason || view.tier?.reason } : view.tier;
  const checks = pr.statusCheckRollup ?? [];
  const failing = checks.filter((c) => checkState(c) === "fail").length;
  const findings = review?.findings ?? [];
  const blocking = findings.filter((f) => ["critical", "high"].includes(f.severity)).length;
  return card(t, "Headline", review ? `agent review · ${review.verdict ?? "no verdict"}` : "path-based tier until an agent reviews it",
    h_flex().gap(10).items_center().flex_wrap()
      .child(tierBadge(t, tier?.tier))
      .child(div().text_size(12).text_color(t.muted).child(tier?.reason ?? ""))
      .when(Boolean(review?.tier && view.tier?.tier && review.tier !== view.tier.tier), (e) => e.child(
        div().text_size(11).text_color(t.dim).child(`first pass said ${view.tier.tier}`))),
    div().text_size(11.5).text_color(t.dim).child(TIER_DEFS[tier?.tier] ?? ""),
    h_flex().gap(8).flex_wrap()
      .child(kpi(t, pr.changedFiles, "files changed"))
      .child(kpi(t, `+${pr.additions} −${pr.deletions}`, "lines"))
      .child(kpi(t, failing ? `${failing}/${checks.length}` : checks.length, failing ? "checks failing" : "checks", failing ? t.blocked : t.done))
      .child(kpi(t, review ? findings.length : "–", review ? `findings · ${blocking} high+` : "findings", blocking ? t.blocked : undefined)));
}

function findingsCard(view, t) {
  const review = view.agentReview;
  if (!review) {
    return card(t, "All findings", view.reviewing ? `${view.reviewing} is reviewing…` : "no agent review yet",
      div().text_size(12).text_color(t.muted).child(view.reviewing
        ? "Findings appear here when the agent writes review.json."
        : "Use “Review with agent” in the header. Findings land here, sorted trunk → branch → leaf."));
  }
  const list = sortFindings(review.findings ?? []);
  const counts = SEVERITIES.map((s) => [s, list.filter((f) => f.severity === s).length]).filter(([, n]) => n);
  return card(t, `All findings (${list.length})`, review.verdict ? `verdict: ${review.verdict}` : "",
    review.summary ? TextView.markdown("review-summary", review.summary).selectable(true) : div(),
    h_flex().gap(6).flex_wrap().children(counts.map(([s, n]) => pill(t, `${n} ${s}`, severityColor(t, s)))),
    v_flex().gap(6).children(list.map((f, i) => {
      const queued = view.comments?.some((c) => c.fromFinding === (f.id ?? i));
      return v_flex().id(`finding-${i}`).gap(4).p(10).rounded(8).bg(t.background).border_1().border_color(t.border)
        .child(h_flex().gap(6).items_center()
          .child(tierBadge(t, f.tier ?? "branch", true))
          .child(pill(t, f.severity ?? "info", severityColor(t, f.severity)))
          .child(div().flex_none().text_size(11).text_color(t.dim).child(f.id ?? ""))
          .child(div().flex_1().min_w(0).truncate().font_semibold().child(f.title ?? "")))
        .when(Boolean(f.file), (e) => e.child(h_flex().gap(8).items_center().text_size(11.5)
          .child(div().id(`finding-file-${i}`).flex_1().min_w(0).truncate().text_color(t.accent).cursor_pointer()
            .on_click((_e, cx) => view.showFile(f.file, f.line, cx)).child(`${f.file}${f.line ? `:${f.line}` : ""}`))
          .when(Boolean(f.line), (row) => row.child(div().id(`finding-queue-${i}`).flex_none().px(8).py(2).rounded(5).cursor_pointer()
            .text_color(queued ? t.done : t.muted).hover((s) => s.bg(t.hover))
            .on_click((_e, cx) => view.queueFinding(f, f.id ?? i, cx)).child(queued ? "✓ queued" : "＋ line comment")))))
        .when(Boolean(f.detail), (e) => e.child(TextView.markdown(`finding-detail-${i}`, f.detail).selectable(true)))
        .when(Boolean(f.suggestion), (e) => e.child(div().text_size(11.5).text_color(t.muted).child(`Suggestion: ${f.suggestion}`)));
    })));
}

function filesFirst(view, t) {
  const files = view.tier?.files ?? [];
  return card(t, "Look at these files first", "trunk → branch → leaf",
    v_flex().gap(2).children(files.slice(0, 40).map((f, i) =>
      h_flex().id(`first-${i}`).gap(8).items_center().px(6).py(4).rounded(6).cursor_pointer().hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => view.showFile(f.path, null, cx))
        .child(tierBadge(t, f.tier, true))
        .child(div().flex_1().min_w(0).truncate().child(f.path))
        .child(div().flex_none().max_w(260).truncate().text_size(11).text_color(t.dim).child(f.reason))
        .child(div().flex_none().text_size(11).text_color(t.ansi2).child(`+${f.additions ?? 0}`))
        .child(div().flex_none().text_size(11).text_color(t.ansi1).child(`−${f.deletions ?? 0}`)))),
    files.length > 40 ? div().text_size(11).text_color(t.dim).child(`and ${files.length - 40} more in Files`) : div());
}

function checksCard(t, pr) {
  const order = { fail: 0, pending: 1, pass: 2 };
  const checks = [...(pr.statusCheckRollup ?? [])].sort((a, b) => order[checkState(a)] - order[checkState(b)]);
  if (!checks.length) return null;
  const icon = { pass: ["✓", t.done], fail: ["✗", t.blocked], pending: ["●", t.working] };
  const failing = checks.filter((c) => checkState(c) === "fail").length;
  return card(t, "Checks run", failing ? `${failing} failing of ${checks.length}` : `${checks.length} passing`,
    v_flex().gap(2).children(checks.map((c, i) => {
      const [glyph, color] = icon[checkState(c)];
      return h_flex().id(`check-${i}`).gap(8).items_center().text_size(12).px(4).rounded(4)
        .when(Boolean(safeUrl(c.detailsUrl || c.targetUrl)), (e) => e.cursor_pointer().hover((s) => s.bg(t.hover)).on_click(() => openUrl(c.detailsUrl || c.targetUrl)))
        .child(div().w(14).text_color(color).child(glyph))
        .child(div().flex_1().min_w(0).truncate().child(c.name || c.context || "check"));
    })));
}

function conversation(t, pr) {
  const items = [
    ...(pr.latestReviews ?? []).map((r) => ({ who: r.author?.login, meta: `${(r.state ?? "").toLowerCase().replace("_", " ")} · ${age(r.submittedAt)} ago`, body: r.body })),
    ...(pr.comments ?? []).map((c) => ({ who: c.author?.login, meta: `${age(c.createdAt)} ago`, body: c.body })),
  ].filter((x) => x.body);
  if (!items.length) return null;
  return card(t, "Reviewer summaries and comments", `${items.length}`,
    v_flex().gap(10).children(items.map((x, i) => v_flex().gap(4)
      .child(h_flex().gap(8).text_size(11.5).child(div().font_semibold().child(x.who ?? "")).child(div().text_color(t.dim).child(x.meta)))
      .child(TextView.markdown(`conversation-${i}`, x.body).selectable(true)))));
}

export function overviewSections(view, t, pr) {
  return [
    headline(view, t, pr),
    findingsCard(view, t),
    filesFirst(view, t),
    card(t, "Description", pr.author?.login ?? "", TextView.markdown("pr-body", pr.body || "_No description_").selectable(true)),
    checksCard(t, pr),
    conversation(t, pr),
  ].filter(Boolean);
}
