# Reviewer feedback — Central Plan Manager (Claude)

Durable copy of my review for GPT. The generated `central-plan-manager-review.html`
is rebuilt by the ChatGPT/Codex desktop app (it re-renders from `proposal.md` /
`design.md` / `tasks.md` / `specs/…`, which wipes any feedback injected into the HTML,
and on at least one render it dropped the `:root {` CSS opener and broke the theme).
This markdown is the regeneration-proof version.

Reviewed against the real repo: `install/link.sh`, `install/claude-backend.sh`,
`claude/settings.base.json`, `claude/output-styles/plan-browser.md`, and the
`~/.agents` / `~/.codex` / `~/.opencode` skill-link layout. Re-checked after the proposal
expanded to add the **Optional Hosted Publishing** phase (Vercel/Blob/Postgres,
`plan push`/`auth`/`remote`), the **Shared Plan Skill Contract**, and non-interactive
`plan create`/`update` with optimistic revisions.

**Overall:** strong, security-conscious core — loopback-only binding, Origin/Host
validation, no CORS, CSRF, atomic writes, path containment, non-destructive migration,
an idempotent linker that never symlinks a whole tool home, and (in the hosted phase)
sanitization + CSP. The findings below are the gaps to resolve before implementation,
roughly by severity. The hosted-publishing expansion also materially changes the
risk/scope calculus (see #7).

---

## Blocker

### 1. How does `plans.localhost` resolve on macOS?
The "one stable URL" premise depends on the browser resolving
`http://plans.localhost:4173/`. Binding the *server* to `127.0.0.1` doesn't help the
*browser's* name resolution. Chrome maps `*.localhost` to loopback; macOS `getaddrinfo`
and (historically) Safari do **not** resolve arbitrary `*.localhost` without an
`/etc/hosts` entry — and adding that needs `sudo`, which `claude/settings.base.json`
explicitly denies (`Bash(sudo *)`), so the installer can't add it non-interactively.
- **Ask:** Which browsers must this support, and what guarantees resolution without a
  privileged hosts edit? If it can't be guaranteed, make the canonical URL
  `http://127.0.0.1:4173/` and treat `plans.localhost` as optional.

### 2. The immutable plan `id` is undefined for externally-created files
Stable ID URLs and the new `--if-revision` optimistic-update machinery require every plan
to carry an immutable `id`. But three main entry paths won't write the YAML schema:
(a) the updated `plan-browser` output style dropping timestamped Markdown, (b) Claude
Code's native plan mode writing to `plansDirectory` in its own format, (c) external-editor
files. Design says reads "normalize missing values in memory" — but an in-memory id isn't
stable across restarts, and "filename normalization … does not change the URL" rules out
deriving it from the filename. These conflict.
- **Ask:** When/how is `id` assigned and *persisted* for a file that arrives without one?
  If the server writes it back on first observation, say so and reconcile with "reads
  never mutate." If derived, from what stable input that survives a rename?

### 3. Comment/format-preserving TOML merge with no TOML parser
Task 4.2 hides the riskiest work: idempotently merging one path into
`sandbox_workspace_write.writable_roots` inside the user's live `~/.codex/config.toml`
while preserving comments, ordering, and unrelated keys. Node has no built-in TOML; the
repo standardizes on `jq` (JSON only). TOML arrays have many valid forms, so a hand-rolled
regex editor is fragile and easily non-idempotent — this is a "corrupt the user's real
Codex config" failure mode.
- **Ask:** What performs this edit? Vendor a small TOML lib (accept the dependency?),
  require `taplo`/`dasel` and gate `plan doctor` on it, or narrow to append-only into a
  canonical array form. Specify idempotency + backup-restore-on-parse-failure.

---

## High

### 4. Local dashboard renders Markdown with no sanitization — while the hosted path does
The hosted phase explicitly sanitizes ("Raw HTML, active content, inline event handlers,
unsafe URL schemes removed… strict CSP"). But the **local** dashboard section still says
only "Pandoc for Markdown rendering." Pandoc passes raw HTML through by default, and plans
may be agent-authored or imported from arbitrary sources. A plan containing `<script>`
then runs in the dashboard's own origin, where it can read the session CSRF token and call
the very mutation endpoints the CSRF/Origin checks protect (stored-XSS → CSRF chain). The
threat model covers cross-origin attackers but not malicious plan *content* — and the two
render paths are now inconsistent.
- **Ask:** Have the local dashboard disable raw HTML (Pandoc `markdown-raw_html`) or
  sanitize, and ship a restrictive CSP. Add a scenario under "Safe Local Web Mutations."

### 5. Scope explosion — split the hosted-publishing phase into its own change
The proposal grew from "central local plan manager" to *also* "build and deploy an
authenticated Vercel app with private Blob + Marketplace Postgres + revocable CLI
credentials + audit + retention + orphan cleanup + conflict handling." That's a second,
larger project with independent infra, security, and cost surface bolted onto a dotfiles
change, and it dilutes review of the core local tool.
- **Ask:** Split hosted publishing into a separate OpenSpec change. Phase 1 = `plan` CLI +
  local dashboard + LaunchAgent + migration; Phase 2 = SSE/live-refresh; Phase 3 (separate
  proposal) = hosted publishing. De-risks the two hardest pieces without blocking core
  value.

---

## Medium

### 6. `KeepAlive` + fixed-port collision = launchd restart loop
Risks say on a port collision "the service remains stopped until resolved," but the
LaunchAgent uses `RunAtLoad` + `KeepAlive`. A bind-failure is an unsuccessful exit, so
plain `KeepAlive: true` relaunches forever (launchd throttles to ~10s). Contradiction.
- **Ask:** Reconcile — e.g. exit `0` (or write a sentinel) on a detected collision so
  launchd doesn't relaunch, and surface it via `plan doctor`. Note `KeepAlive =
  {SuccessfulExit=false}` still restarts on a crash.

### 7. Heterogeneous schema: mutating Claude's native plan files
With `plansDirectory` pointing at the library, Claude's native plan mode writes *its*
format into the same root. `plan status`/`plan archive` then rewrite frontmatter on files
Claude also owns and re-reads, which could confuse Claude or drop fields.
- **Ask:** Is co-locating Claude's native files with managed files intended, and what's the
  contract when the manager rewrites a Claude-authored file? Confirm normalization is
  non-lossy for unknown keys.

### 8. Hosted "ownership"/multi-tenant model is ambiguous for a personal tool
The spec says the hosted API "verifies plan ownership" and stores an "owner" in
"Marketplace Postgres" — implying multi-user/tenant authz. But this is a personal dotfiles
setup. If single-user, ownership verification is over-built; if multi-user, that's a much
larger security design (user management, authz model) than documented.
- **Ask:** State the tenancy model. Single-user changes the whole hosted design's weight.

---

## Low / Nits

- **Port 4173 is Vite's default preview port** — a running `vite preview` will trip the
  (intentional) fixed-port collision often on a dev machine. Was 4173 chosen deliberately
  over a less-contended port? A note in Risks would preempt confusion.
- **Backup-on-conflict diverges from the existing `link.sh` convention.** The current
  script is uniformly "skip if destination exists"; the new managed-file linker moves
  conflicts to timestamped backups then links. Good improvement — add a one-line rationale
  so a future reader doesn't "fix" it back to skipping.
- **Several acceptance items are inherently manual** — Verification 5.5 (Codex desktop from
  an unrelated repo), 5.7 (wake-from-sleep / missed watcher event), the "UI browser checks"
  in 5.8 (which also depend on the `plans.localhost` resolution question). Mark manual vs.
  automated so "strict validation" doesn't imply CI coverage it can't have.
- **CLI surface roughly doubled** (`new`/`create`, `edit`/`update`, plus 7 `remote`/`auth`/
  `push` commands). Not wrong, but keep the interactive-vs-non-interactive pairing and JSON
  envelope consistent, and consider whether the hosted commands belong in the split-out
  change (#5).

---

## Strengths worth keeping
- Loopback-only bind + Host/Origin validation + no CORS + CSRF on mutations.
- Atomic writes, path containment, ambiguous-identifier safety, non-destructive imports
  that preserve originals; explicit (non-automatic) migration.
- Idempotent linker with timestamped backups that never symlinks a whole tool home and
  never follows a destination symlink; resolves `$HOME`/paths without committing a username.
- Not symlinking the whole Codex `config.toml` (machine-local state) — only a targeted
  merge with a pre-mutation backup.
- Hosted phase: sanitization + strict CSP, private Blob, conditional-revision conflict
  rejection, keychain-only scoped credentials, explicit opt-in publishing boundary.
- `plan doctor` as a single health/diagnostic surface; JSON envelopes + documented exit
  codes for agent use; the Shared Plan Skill Contract's clear trigger boundary and
  "report failure, don't claim success" rule.
