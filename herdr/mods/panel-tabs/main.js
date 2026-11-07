import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { layout, run, shared, theme } from "herdr";

const TABS = [["files", "Files"], ["changes", "Changes"], ["pulls", "PRs"], ["plans", "Plans"], ["fleet", "Fleet"]];

function findNode(tree, id) {
  if (!tree || typeof tree !== "object") return null;
  if (tree.id === id) return tree;
  for (const child of tree.children ?? []) {
    const found = findNode(child, id);
    if (found) return found;
  }
  return null;
}

export default class PanelTabs extends View {
  render() {
    const t = theme();
    const raw = findNode(layout(), "panel-body")?.active;
    const active = raw === "pr-changes" ? "changes" : raw;
    const target = (id) => (id === "changes" && shared("dotfiles.activePr") ? "pr-changes" : id);
    return h_flex().id("root").size_full().px(6).gap(2).items_end().bg(t.chrome).border_b(1).border_color(t.border).text_size(12)
      .children(TABS.map(([id, label]) => div().id(`panel-tab-${id}`).px(10).py(6).cursor_pointer()
        .border_b(2).border_color(active === id ? t.accent : t.chrome)
        .text_color(active === id ? t.foreground : t.muted)
        .hover((s) => s.text_color(t.foreground))
        .on_click(() => run("layout.select", { stack: "panel-body", child: target(id) }))
        .child(label)))
      .child(div().flex_1())
      .child(div().id("panel-close").px(8).py(6).cursor_pointer().text_color(t.dim).hover((s) => s.text_color(t.foreground))
        .on_click(() => run("layout.hide", { id: "panel" })).child("✕"));
  }
}
