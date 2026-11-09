import { exec, focused, home, run } from "herdr";
import { TIER_DEFS } from "./tier.js";

let personalOwners = new Set();

export const ownersReady = exec("git", ["config", "--get-regexp", "^github\\.(user|org)$"])
  .then((r) => {
    if (r.code !== 0) return;
    personalOwners = new Set(r.stdout.split("\n").map((line) => line.split(/\s+/)[1]?.toLowerCase()).filter(Boolean));
  })
  .catch(() => {});

export const AGENTS = [
  { id: "codex", label: "Codex", personal: true, skill: "$pr-review", argv: (prompt) => ["codex", prompt] },
  { id: "claude-personal", label: "Claude · personal", personal: true, skill: "/pr-review", argv: (prompt) => ["claude-personal", prompt] },
  { id: "copilot", label: "GitHub Copilot", personal: false, skill: "/pr-review", argv: (prompt) => ["copilot", "-i", prompt] },
  { id: "claude-work", label: "Claude · work", personal: false, skill: "/pr-review", argv: (prompt) => ["claude-subscription", prompt] },
  { id: "claude-foundry", label: "Claude · Foundry", personal: false, skill: "/pr-review", argv: (prompt) => ["claude-foundry", prompt] },
];

export function parsePrUrl(url) {
  const m = /github\.com\/([^/]+)\/([^/]+)\/pull\/(\d+)/.exec(url ?? "");
  return m ? { owner: m[1], repo: m[2], number: m[3] } : null;
}

export function isPersonalRepo(url) {
  const pr = parsePrUrl(url);
  return !!pr && personalOwners.has(pr.owner.toLowerCase());
}

export function agentsFor(url) {
  const personal = isPersonalRepo(url);
  return AGENTS.map((a) => ({ ...a, allowed: a.personal === personal }));
}

export function reviewDir(url) {
  const pr = parsePrUrl(url);
  return pr ? `${home()}/.local/state/herdr-pr-reviews/${pr.owner}/${pr.repo}/${pr.number}` : null;
}

export function reviewFile(url) {
  const dir = reviewDir(url);
  return dir ? `${dir}/review.json` : null;
}

function prompt(agent, url, tier) {
  return [
    `${agent.skill} ${url}`,
    "",
    "Review this pull request with the trunk → branch → leaf priority model:",
    `- trunk: ${TIER_DEFS.trunk}`,
    `- branch: ${TIER_DEFS.branch}`,
    `- leaf: ${TIER_DEFS.leaf}`,
    `A path-based first pass labels this PR ${tier.tier} (${tier.reason}); confirm or correct it.`,
    "Review trunk files first, then branch, then leaf. Severity ranks findings only within a tier, except that a critical finding is always first.",
    "Do not post anything to GitHub: the reviewer reads your findings in Herdr and submits the review there.",
    "",
    "When you finish, write ./review.json in the current folder, exactly this JSON shape:",
    '{"verdict": "Approve" | "Request changes" | "Comment", "tier": "trunk" | "branch" | "leaf", "tier_reason": "...", "summary": "...",',
    ' "findings": [{"id": "F1", "severity": "critical" | "high" | "medium" | "low" | "info", "tier": "trunk" | "branch" | "leaf",',
    '   "file": "path/in/repo", "line": 123, "title": "...", "detail": "...", "suggestion": "..."}]}',
    "Use the new-file line number of a changed or context line for `line`, or null when a finding has no single line.",
  ].join("\n");
}

export async function launchReview(agentId, url, tier, title) {
  const agent = AGENTS.find((a) => a.id === agentId);
  const dir = reviewDir(url);
  if (!agent || !dir) throw new Error("Unknown agent or pull request");
  await ownersReady;
  if (!agentsFor(url).find((a) => a.id === agentId)?.allowed) throw new Error(`${agent.label} is not allowed for this repository`);
  const made = await exec("mkdir", ["-p", dir]);
  if (made.code !== 0) throw new Error(made.stderr.trim());
  const argv = ["zsh", "-c", 'cd "$1" && shift && exec "$@"', "zsh", dir, ...agent.argv(prompt(agent, url, tier))];
  const pane = focused()?.pane;
  if (pane) run("pane.split", { direction: "right", pane, argv });
  else run("tab.new", { folder: dir, argv: agent.argv(prompt(agent, url, tier)), name: `review ${title ?? ""}`.trim() });
  return agent;
}
