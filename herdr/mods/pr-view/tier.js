export const TIERS = ["trunk", "branch", "leaf"];

export const TIER_DEFS = {
  trunk: "Major or cross-cutting change: authentication and authorization, identity, secrets, CI/CD, IaC, APIM, dependencies, startup, and public API or catalog contracts.",
  branch: "One service, feature or endpoint family changes, so the blast radius is one area.",
  leaf: "A single function, type or local detail: naming, a pass-through, tests, or docs.",
};

export const TIER_ICON = { trunk: "🌳", branch: "🌿", leaf: "🍃" };

const TRUNK = [
  [/(^|\/)(\.github\/workflows|\.azure-pipelines|pipelines?|ci)\/|azure-pipelines[^/]*\.ya?ml$|\.gitlab-ci\.ya?ml$|jenkinsfile$/i, "CI/CD pipeline: affects every build and deployment"],
  [/\.(tf|tfvars|bicep)$|(^|\/)(infra|iac|terraform|bicep|helm|k8s|kubernetes|deploy|deployment)\//i, "Infrastructure as code"],
  [/(auth|identity|oauth|oidc|jwt|token|permission|rbac|policies|policy|scope)/i, "Authentication and authorization: decides who can call it"],
  [/(secret|key-?vault|credential|certificate|\.env($|\.))/i, "Secrets, Key Vault and credential flow"],
  [/(^|\/)apim\/|api-?management/i, "APIM gateway configuration"],
  [/(^|\/)(package(-lock)?\.json|pnpm-lock\.yaml|yarn\.lock|go\.(mod|sum)|[^/]+\.csproj|Directory\.(Build|Packages)\.props|requirements[^/]*\.txt|pyproject\.toml|poetry\.lock|Cargo\.(toml|lock)|Gemfile(\.lock)?|Dockerfile[^/]*|global\.json|nuget\.config)$/i, "Dependency or package surface of the whole application"],
  [/(^|\/)(Program\.cs|Startup\.cs|appsettings[^/]*\.json|main\.(go|ts|js|py)|server\.(ts|js)|app\.(ts|js|py)|settings\.py)$|(^|\/)config(uration)?s?\//i, "App startup and configuration: every request depends on it"],
  [/(openapi|swagger|\.proto$|schema\.graphql$|(^|\/)contracts?\/|catalog)/i, "Public API or catalog contract every client relies on"],
];

const LEAF = [
  [/(^|\/)(tests?|__tests__|spec|specs|testdata|fixtures)\/|\.(test|spec)\.[a-z]+$|Tests?\.cs$|_test\.go$|test_[^/]+\.py$/i, "Test-support code only"],
  [/\.(md|mdx|txt|rst|adoc)$|(^|\/)docs?\//i, "Documentation only"],
];

export function classifyFile(path, changes = 0) {
  for (const [pattern, reason] of LEAF) if (pattern.test(path)) return { tier: "leaf", reason };
  for (const [pattern, reason] of TRUNK) if (pattern.test(path)) return { tier: "trunk", reason };
  if (changes > 0 && changes <= 10) return { tier: "leaf", reason: "A small local change" };
  return { tier: "branch", reason: "Feature or service code: one area of the application" };
}

export function classifyPr(files) {
  const list = (files ?? []).map((f) => ({ ...f, ...classifyFile(f.path, (f.additions ?? 0) + (f.deletions ?? 0)) }));
  if (!list.length) return { tier: "leaf", reason: "No changed files", files: list };
  const rank = (t) => TIERS.indexOf(t);
  const top = list.reduce((best, f) => (rank(f.tier) < rank(best.tier) ? f : best), list[0]);
  let { tier, reason } = top;
  if (tier === "leaf" && list.filter((f) => f.tier === "leaf" && !/only$/.test(f.reason)).length > 1) {
    tier = "branch";
    reason = "Several local changes across files";
  }
  list.sort((a, b) => rank(a.tier) - rank(b.tier) || ((b.additions ?? 0) + (b.deletions ?? 0)) - ((a.additions ?? 0) + (a.deletions ?? 0)));
  return { tier, reason, files: list };
}
