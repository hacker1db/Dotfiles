local M = {}

M.TIERS = { "trunk", "branch", "leaf" }

M.ICON = { trunk = "🌳", branch = "🌿", leaf = "🍃" }

M.HL = { trunk = "DiagnosticError", branch = "DiagnosticWarn", leaf = "DiagnosticOk" }

M.DEFS = {
  trunk = "Major or cross-cutting change: authentication and authorization, identity, secrets, CI/CD, IaC, APIM, dependencies, startup, and public API or catalog contracts.",
  branch = "One service, feature or endpoint family changes, so the blast radius is one area.",
  leaf = "A single function, type or local detail: naming, a pass-through, tests, or docs.",
}

M.EFFORT = { trunk = "line by line", branch = "logic and edge cases", leaf = "skim" }

local function rules(list)
  return vim.tbl_map(function(r)
    return { re = vim.regex([[\v\c]] .. r[1]), reason = r[2] }
  end, list)
end

local TRUNK = rules({
  { [[(^|/)(\.github/workflows|\.azure-pipelines|pipelines?|ci)/|azure-pipelines[^/]*\.ya?ml$|\.gitlab-ci\.ya?ml$|jenkinsfile$]], "CI/CD pipeline: affects every build and deployment" },
  { [[\.(tf|tfvars|bicep)$|(^|/)(infra|iac|terraform|bicep|helm|k8s|kubernetes|deploy|deployment)/]], "Infrastructure as code" },
  { [[(auth|identity|oauth|oidc|jwt|token|permission|rbac|policies|policy|scope)]], "Authentication and authorization: decides who can call it" },
  { [[(secret|key-?vault|credential|certificate|\.env($|\.))]], "Secrets, Key Vault and credential flow" },
  { [[(^|/)apim/|api-?management]], "APIM gateway configuration" },
  { [[(^|/)(package(-lock)?\.json|pnpm-lock\.yaml|yarn\.lock|go\.(mod|sum)|[^/]+\.csproj|Directory\.(Build|Packages)\.props|requirements[^/]*\.txt|pyproject\.toml|poetry\.lock|Cargo\.(toml|lock)|Gemfile(\.lock)?|Dockerfile[^/]*|global\.json|nuget\.config)$]], "Dependency or package surface of the whole application" },
  { [[(^|/)(Program\.cs|Startup\.cs|appsettings[^/]*\.json|main\.(go|ts|js|py)|server\.(ts|js)|app\.(ts|js|py)|settings\.py)$|(^|/)config(uration)?s?/]], "App startup and configuration: every request depends on it" },
  { [[(openapi|swagger|\.proto$|schema\.graphql$|(^|/)contracts?/|catalog)]], "Public API or catalog contract every client relies on" },
})

local LEAF = rules({
  { [[(^|/)(tests?|__tests__|spec|specs|testdata|fixtures)/|\.(test|spec)\.[a-z]+$|Tests?\.cs$|_test\.go$|test_[^/]+\.py$]], "Test-support code only" },
  { [[\.(md|mdx|txt|rst|adoc)$|(^|/)docs?/]], "Documentation only" },
})

function M.rank(tier)
  return vim.fn.index(M.TIERS, tier or "branch")
end

function M.classify_file(path, changes)
  for _, r in ipairs(LEAF) do
    if r.re:match_str(path) then return { tier = "leaf", reason = r.reason } end
  end
  for _, r in ipairs(TRUNK) do
    if r.re:match_str(path) then return { tier = "trunk", reason = r.reason } end
  end
  if (changes or 0) > 0 and changes <= 10 then
    return { tier = "leaf", reason = "A small local change" }
  end
  return { tier = "branch", reason = "Feature or service code: one area of the application" }
end

function M.classify_pr(files)
  local list = {}
  for _, f in ipairs(files or {}) do
    local changes = (f.additions or 0) + (f.deletions or 0)
    list[#list + 1] = vim.tbl_extend("force", f, M.classify_file(f.path, changes), { changes = changes })
  end
  if #list == 0 then
    return { tier = "leaf", reason = "No changed files", files = list }
  end
  local top = list[1]
  for _, f in ipairs(list) do
    if M.rank(f.tier) < M.rank(top.tier) then top = f end
  end
  local tier, reason = top.tier, top.reason
  if tier == "leaf" then
    local local_changes = 0
    for _, f in ipairs(list) do
      if f.tier == "leaf" and not f.reason:match("only$") then local_changes = local_changes + 1 end
    end
    if local_changes > 1 then
      tier, reason = "branch", "Several local changes across files"
    end
  end
  table.sort(list, function(a, b)
    if a.tier ~= b.tier then return M.rank(a.tier) < M.rank(b.tier) end
    return a.changes > b.changes
  end)
  return { tier = tier, reason = reason, files = list }
end

return M
