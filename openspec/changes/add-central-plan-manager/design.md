## Context

The dotfiles repository already configures shell `PATH`, links shared skills into Claude Code, Copilot, Codex, and OpenCode, and installs Node.js, pnpm, and Pandoc. The plan-manager implementation now belongs in a dedicated Git repository rooted at `~/Developer/sites/plan-manager`; dotfiles owns only its bootstrap, command link, service integration, and agent instructions. Tool-specific `/plan` commands cannot be the portable interface because Codex and Copilot reserve `/plan` for their built-in planning modes.

## Goals / Non-Goals

- Goals: one Markdown source of truth, one separately versioned application repository, one CLI, one stable local dashboard, automatic local serving, safe imports, native agent discovery, reproducible bootstrap from the dotfiles repository on every Mac, and an optional authenticated hosted mirror for plans explicitly published by the user.
- Non-Goals: making the cloud copy canonical, automatic bidirectional synchronization, collaborative or browser-based Markdown editing, public sharing, replacing built-in planning modes, or taking ownership of tool authentication and session-state directories.

## Decisions

### Repository ownership and checkout resolution

The `plan-manager` repository owns:

- The executable entry point at `bin/plan`.
- Local CLI, server, rendering, metadata, and dashboard code.
- The optional hosted Next.js application and database migrations.
- Application dependencies, lockfile, tests, and application documentation.

The dotfiles repository owns:

- A tracked default repository identifier and environment-variable overrides.
- Clone and checkout reconciliation in `install/link.sh`.
- The managed command link, shell `PATH`, LaunchAgent template, agent skill, global instructions, and tool adapters.

The target repository root is `~/Developer/sites/plan-manager`, overridable through `PLAN_MANAGER_REPO_DIR`. A resolved executable checkout may be:

1. A normal Git worktree at the target root.
2. A linked worktree selected through `PLAN_MANAGER_WORKTREE`.
3. A bare-worktree layout where the target contains `.bare` and the default worktree is `main/`.

The current machine uses the third layout, so its application worktree resolves to `~/Developer/sites/plan-manager/main`. Fresh machines may use a normal clone at the target root. The bootstrap reports the resolved worktree and uses that single path consistently for dependency installation, the executable link, LaunchAgent generation, and `plan doctor`.

`PLAN_MANAGER_REPO_URL` is the authoritative override for cloning. If it is unset, the bootstrap may derive `git@github.com:<authenticated-gh-user>/plan-manager.git` only when `gh` is authenticated. If neither an override nor an authenticated GitHub identity is available, it reports that the application repository cannot be cloned and does not fabricate a remote. The existing repository currently has no configured origin, so cross-machine bootstrap remains incomplete until the user adds a reachable remote or supplies the override.

When the target is missing, the installer creates only its parent and performs a normal clone. When the target exists, it resolves and validates a worktree before changing anything. A non-Git target, unreadable Git metadata, unexpected origin, missing expected worktree, or missing executable fails visibly without deletion or replacement. A dirty worktree is never pulled, reset, cleaned, stashed, or switched. A clean checkout with the expected origin may be fast-forwarded only; divergence is reported for manual resolution.

The repository provides a committed pnpm lockfile and an executable `bin/plan` with a portable shebang. The application source is TypeScript and is compiled with strict `tsc` before the executable is linked; generated JavaScript lives in ignored build output and the runtime never loads TypeScript source directly. Canonical plan metadata, status values, parsed-plan records, JSON envelopes, and CLI options use shared TypeScript interfaces and closed status unions. The linker runs a frozen pnpm dependency install followed by the TypeScript build, validates the executable with `plan --version`, and creates or repairs a managed symlink at `~/.local/bin/plan`. Shell configuration includes `~/.local/bin` on `PATH` without embedding a machine username. It never installs the CLI through an unrelated global npm package or copies application source into dotfiles.

`pnpm dev` runs the TypeScript source in watch mode and starts the same loopback server at `http://plans.localhost:4173` by default. It binds only to `127.0.0.1`; the friendly hostname remains the canonical browser URL in development, tests, and installed use. The packaged dashboard serves its generated favicon locally at `/icon.png` and both library and detail documents declare it.

### Storage

`~/Developer/plans` is the canonical root. Managed files use YAML frontmatter with `id`, `title`, `status`, `created`, `updated`, `tags`, and optional `source`. Status values are `active`, `completed`, and `archived`.

The CLI creates the root and an `archive/` subdirectory when missing. If either expected directory path is occupied by a non-directory, it exits with a clear error and makes no changes.

Imports copy Markdown into the root, add normalized metadata to the copy, and never alter or remove the source. Archived plans move into `archive/` through a same-filesystem atomic rename.

### CLI

The executable is resolved from the dedicated application worktree and linked to `~/.local/bin/plan`. It provides:

- `plan` and `plan open`: ensure the service is available and open the dashboard.
- `plan init`: initialize and validate the plan home.
- `plan new <title>`: create a uniquely named Markdown plan and open it in `$EDITOR`.
- `plan create --title <title> [--stdin|--file <file>] [--json]`: create a complete plan non-interactively.
- `plan import <file>`: copy an existing `.md` file into the managed library.
- `plan capture <artifact> [--title <title>] [--json]`: idempotently capture an external Markdown artifact or convert standalone HTML through Pandoc, preserve the source, and retain the existing plan ID and URL when the same absolute source changes.
- `plan list [--status <value>] [--json]`: list normalized metadata.
- `plan search <query> [--json]`: search titles, tags, and Markdown content.
- `plan show <id-or-slug> [--json]`: render a plan in the terminal or return its metadata and Markdown.
- `plan edit <id-or-slug>`: open the Markdown source in `$EDITOR`.
- `plan update <id-or-slug> [--stdin|--file <file>] [--if-revision <revision>] [--json]`: replace plan content non-interactively and reject stale revisions.
- `plan status <id-or-slug> <active|completed|archived>`: update status atomically.
- `plan archive <id-or-slug>`: archive a plan atomically.
- `plan serve [--foreground] [--json]`: ensure the loopback server is running idempotently.
- `plan doctor [--json]`: validate storage, dependencies, LaunchAgent state, port availability, and dashboard health.
- `plan remote add <name> <url>`: add or update a named hosted plan service.
- `plan remote list [--json]`: list configured hosted services without exposing credentials.
- `plan auth login [--remote <name>]`: authenticate the CLI and store the resulting credential in the operating-system keychain.
- `plan auth logout [--remote <name>]`: revoke or remove the selected hosted credential.
- `plan push <id-or-slug|--all> [--remote <name>] [--json]`: upload canonical Markdown to a configured hosted service.
- `plan remote status <id-or-slug> [--remote <name>] [--json]`: compare the local content hash and last-known hosted revision.
- `plan open <id-or-slug> --remote [<name>]`: open the stable authenticated hosted route.

Commands resolve only files contained by the canonical root after path normalization. Ambiguous identifiers fail with matching candidates instead of selecting arbitrarily.

Machine-readable mutations return a versioned JSON envelope containing at least the plan ID, canonical path, stable dashboard URL, and current revision. Machine-readable health commands return the dashboard URL and service state. JSON mode writes only the envelope to standard output, sends diagnostics to standard error, and uses documented nonzero exit codes for invalid input, ambiguity, conflicts, and unavailable dependencies.

Remote configuration contains only service names, base URLs, plan revisions, and content hashes. Authentication credentials are never written to dotfiles, plan frontmatter, shell history, or the plan library.

### Dashboard and server

Use Node.js core modules for the server and Pandoc for Markdown rendering. Do not add a framework, database, CDN, or remote font dependency. Scan Markdown on demand so the filesystem remains the source of truth.

Serve `http://plans.localhost:4173/`, accept `127.0.0.1` as a fallback host, and bind only to `127.0.0.1`. A fixed port is intentional; a collision is reported instead of silently changing the URL.

The dashboard provides full-text search, status and tag filters, Markdown rendering, status changes, archive, copy-path, and open-in-editor actions. It does not edit Markdown in the browser. Mutating requests require same-origin checks and a session CSRF token; the server rejects unexpected Host and Origin headers and never enables CORS.

Each plan has a stable route based on its immutable metadata ID, such as `http://plans.localhost:4173/plans/<id>`. Title changes, filename normalization, status changes, and moves into `archive/` do not change that URL.

The server detects library changes from CLI commands, supported agents, dashboard actions, and external editor saves. Use Node.js filesystem watching with a debounced periodic fingerprint rescan so atomic renames and missed watcher events are handled without adding a dependency. The server publishes monotonic library and plan revision events over a same-origin Server-Sent Events endpoint.

When the open plan's revision changes, the browser reloads its current location rather than navigating to a generated or tool-specific page. The stable ID route resolves the updated Markdown and preserves the same URL, including any query string or fragment. Library-list pages refresh their visible data without changing the current route. Unrelated plan changes do not interrupt an open plan detail view.

The event client reconnects automatically. After reconnection or computer wake, it compares the last known revision with the current server revision and reloads the same page if it became stale while disconnected. Change events are emitted only after a debounced rescan produces a stable fingerprint, preventing partial external writes from causing a reload loop.

The interface uses an editorial, document-library aesthetic with local CSS and restrained motion. It must remain usable without internet access and at narrow viewport widths.

### Startup and adapters

Install a generated macOS LaunchAgent that runs `plan serve --foreground` at login with `RunAtLoad` and `KeepAlive`. Installer generation resolves the current home path without committing a username.

The portable interface is always the `plan` executable. Add a shared `plans` skill that delegates every operation to that executable:

- Claude Code: `/plans`
- OpenCode: `/plans`
- Copilot CLI: `/plans`
- Codex: `$plans` or selection through `/skills`

The plural adapter name avoids conflicts with the built-in `/plan` modes in Codex and Copilot. Natural-language requests may trigger the skill automatically, but adapters do not implement storage or server behavior themselves.

Keep the skill portable and progressively disclosed:

```text
claude/skills/plans/
├── SKILL.md
├── references/
│   ├── cli.md
│   ├── server.md
│   └── remote.md
└── evals/
    └── evals.json
```

`SKILL.md` stays concise and defines the trigger boundary: use it when the user asks to create, save, update, find, review, open, complete, archive, or explicitly publish a user-facing plan. It distinguishes those durable deliverables from transient reasoning and internal task lists. `references/cli.md` documents the authoritative command syntax, JSON schema, exit behavior, and non-interactive examples. `references/server.md` documents the stable local URL, `plan serve` and `plan doctor` health workflow, same-page refresh behavior, and failure reporting. `references/remote.md` documents opt-in publishing, authentication, conflict handling, privacy, and hosted URL reporting.

The skill never reimplements storage, edits canonical files directly, calls private dashboard mutation endpoints, or publishes a plan merely because it was created or updated. It invokes the `plan` CLI in non-interactive JSON mode, uses optimistic revisions for updates, ensures the local service is healthy through the CLI, and returns the plan ID plus stable local dashboard URL. It invokes `plan push` only after an explicit publish request or an already-configured user policy and then returns both local and hosted URLs. If persistence, publishing, or service startup fails, it reports the command failure without claiming the plan is saved, uploaded, or reviewable.

Add 2-3 realistic eval prompts covering creation from a non-interactive agent session, updating an existing plan while retaining its stable URL, and finding or opening a plan while the service is stopped. Assertions verify CLI delegation, canonical storage, service recovery, ID and URL output, and preservation of native planning modes.

### Optional hosted publishing

Deploy one authenticated Next.js application to Vercel. Publishing a plan changes application data through a versioned Route Handler; it does not run `vercel deploy` and does not create a deployment, project, or static site for each plan. The hosted application provides a library route and stable plan route such as `https://<configured-host>/plans/<id>`.

The local library remains authoritative. Hosted publishing is opt-in and one-way in the initial release:

1. `plan push` reads the canonical Markdown only after local metadata validation succeeds.
2. The CLI computes a SHA-256 content hash and sends the UTF-8 Markdown bytes to `PUT /api/v1/plans/<id>` with an application bearer credential and the last-known hosted revision.
3. The hosted API authenticates the credential, verifies plan ownership, enforces an upload-size limit, validates the ID and frontmatter, and rejects unsafe or malformed input.
4. The API writes an immutable private Blob object at a versioned key derived from the owner, plan ID, and content hash.
5. A Marketplace Postgres transaction records the owner, plan ID, title, status, tags, private Blob pathname, content hash, revision, and timestamps. The database never stores the CLI bearer credential in plaintext.
6. After the database pointer is committed, superseded Blob versions become eligible for bounded retention cleanup. Failed database commits leave an unreferenced object that cleanup may remove; they never replace the visible hosted revision.
7. The response returns a versioned JSON envelope containing the unchanged plan ID, hosted revision, content hash, and stable authenticated URL.

The CLI sends the previous hosted revision using a conditional request. A stale revision returns a conflict and does not replace the hosted copy. `plan push --all` processes plans independently and reports partial success without claiming an atomic library-wide publish. Network, authentication, or hosted-storage failures do not modify local Markdown or prevent the local dashboard from working.

Browser sessions and CLI credentials are separate. The browser uses the application's normal session authentication. The CLI uses revocable, scoped application credentials stored in the macOS Keychain; the CLI never receives Vercel, database, Blob, or deployment credentials. The hosted API authenticates and authorizes every request in the Route Handler, applies rate and size limits, and records token identifiers rather than secrets in audit data.

Private Markdown is rendered only after server-side sanitization. Raw HTML, active content, inline event handlers, and unsafe URL schemes are removed or rejected, and the hosted dashboard uses a strict Content Security Policy. The authorized download route streams the stored object as `text/markdown` so the exact published file remains retrievable without exposing the private Blob URL.

The hosted detail page retains the same route across pushes. After a successful push, the application invalidates the plan's cached data. An already-open page compares its displayed revision with a lightweight authenticated revision endpoint and refreshes the same route when a newer revision appears. Realtime infrastructure and bidirectional editing remain out of scope for the initial hosted phase.

Use private Vercel Blob for Markdown objects and Marketplace Postgres for indexing, ownership, revisions, token records, and search. Keep provider access lazy and server-only so missing hosted environment variables do not break the local CLI or unrelated build paths. Hosted deployment and storage provisioning are documented separately from `install/link.sh`; cloning the dotfiles repository must not create cloud resources or require Vercel access.

### Dotfiles-managed client configuration

Keep the shared workflow in `claude/skills/plans/`, which the existing skill installer links into Claude Code, Copilot, Codex, and OpenCode. Add thin global instruction sources to the repository so each client is told to invoke the shared skill for user-facing plan operations and persist them through the `plan` executable:

- Claude Code: add the central policy to the existing Plan Browser output style and set `plansDirectory` to `~/Developer/plans` in `claude/settings.base.json`. Continue using `install/claude-backend.sh` to merge backend-specific settings and link the generated result to `~/.claude/settings.json`.
- OpenCode: add a global `AGENTS.md` within the tracked `config/opencode/` directory. Preserve the built-in Plan agent and existing provider/model selection; the rule tells it to use the `plans` skill and portable CLI.
- Copilot CLI: add a tracked `copilot/copilot-instructions.md` and link it to `~/.copilot/copilot-instructions.md`. Preserve `~/.copilot/settings.json`, authentication, permissions, session state, and caches.
- Codex desktop and CLI: add a tracked `codex/AGENTS.md` and link it to `~/.codex/AGENTS.md`. Codex discovers the shared `plans` skill from `~/.agents/skills/plans`, with the existing `~/.codex/skills` link retained for compatibility. Both surfaces continue using native planning mode and invoke the central manager through `$plans`.

The global instruction text defines a user-facing plan as an implementation, project, investigation, migration, deployment, or other plan presented as a deliverable. It excludes transient reasoning and brief internal task lists. For every in-scope plan, the client must use the central library, avoid a tool-specific canonical copy, ensure the local service is healthy, and return the plan identifier plus dashboard URL.

Do not set or change a plan-specific model without an explicit model choice from the user. The installation preserves the current Claude, OpenCode, Copilot, and Codex model configuration.

Codex loads global guidance once at the beginning of a run, so installation instructions require starting a new desktop task or CLI session after linking. `plan doctor` reports a non-empty `~/.codex/AGENTS.override.md` because it shadows the managed global `AGENTS.md`.

Codex normally limits workspace-write access to the active workspace. Add a tracked, machine-independent Codex configuration fragment describing the required plan-library permission. During linking, resolve the current home directory and idempotently merge the absolute `~/Developer/plans` path into `sandbox_workspace_write.writable_roots` in the existing `~/.codex/config.toml`.

The merge preserves existing writable roots and every unrelated Codex setting, including model, reasoning, approval policy, sandbox mode, providers, plugins, memories, sessions, and authentication. It does not force `sandbox_mode`, weaken the approval policy, or replace the complete config file. If a managed application or organization policy overrides the local writable-root setting, Codex may still request approval and `plan doctor` reports that effective-access limitation.

### Link-script reconciliation

Extend `install/link.sh` with a reusable repository bootstrapper, a managed-file linker for the CLI plus Copilot and Codex global instruction files, and a format-aware Codex configuration reconciler. The reconcilers:

- Clone a missing `plan-manager` repository only after resolving an explicit or authenticated default remote.
- Support a normal clone, an explicitly selected linked worktree, and the current `.bare` plus `main/` worktree layout.
- Verify the expected remote and worktree before fetching or linking.
- Preserve dirty or divergent checkouts and report the manual action required.
- Install application dependencies from the committed lockfile and validate `bin/plan` before linking it to `~/.local/bin/plan`.
- Creates only the required parent directories, never an entire replacement tool home.
- Creates missing symlinks and repairs broken or incorrect symlinks.
- Treats an already-correct symlink as a no-op.
- Moves an unmanaged conflicting file to a timestamped same-directory backup before linking the dotfiles source.
- Never follows a destination symlink when choosing a backup or replacement target.
- Merge the resolved plan root into Codex's existing writable-root array without removing other roots or changing unrelated TOML keys.
- Create a timestamped same-directory backup before the first Codex config mutation and write the updated config atomically.
- Reports every created, repaired, backed-up, or unchanged target.

Continue using the existing OpenCode directory symlink and Claude generated-settings workflow instead of adding parallel link mechanisms. Do not symlink the complete Codex config because it contains machine-local and user-managed state. Generate the LaunchAgent from a tracked template because launchd requires resolved absolute executable paths; do not commit a username. `install/link.sh` resolves `$HOME`, the application worktree, Node.js, pnpm, Pandoc, and the linked `plan` executable, writes machine-local configuration atomically, bootstraps or refreshes the LaunchAgent with `launchctl`, initializes the plan library, and finishes with `plan doctor`.

The link operation is idempotent. A second run with unchanged sources must leave user data untouched, keep the same symlink targets, and return success. If Node.js or Pandoc is missing, instruction links may still be installed, but service installation fails visibly and `plan doctor` reports the missing dependency.

### Migration

Change `plan-browser` to create Markdown in `~/Developer/plans` and open the centralized dashboard rather than generating adjacent HTML. During installation, do not migrate data automatically. Document and test an explicit `plan import ~/.claude/plans/<file>.md` migration so existing files are preserved.

Every supported harness keeps its native planning mechanics, but finalized durable outputs are not exempt from central persistence. Before its final response, the harness verifies that each durable plan artifact has a successful plan-manager result. It uses `plan create` or `plan update` when canonical Markdown is available and `plan capture` as the fallback for Markdown or standalone HTML without managed metadata. Capture is explicit rather than a filesystem crawler: HTML is converted to GitHub-flavored Markdown through Pandoc, external sources remain unchanged, unmanaged Markdown already inside the library is normalized in place, and repeated capture of the same absolute source updates the existing managed plan only when content changed.

All CLI and dashboard mutations use one bounded library writer lock. Concurrent captures of one source converge on one plan ID, while different sources or creation commands with the same inferred title receive collision-free paths. Revision assertions and writes occur within the same lock so concurrent optimistic updates produce one winner and stale conflicts for the rest. Capture acquires the lock before reading an unmanaged in-library source so it cannot overwrite an edit made while waiting. The lock uses an atomically created directory with a refreshed lease so a crashed process cannot block writers permanently and an active long-running mutation does not appear stale. During migration from the original PID-file implementation, a dead or expired legacy lock and its legacy recovery guard are removed before the lease-backed lock is acquired.

## Risks / Trade-offs

- The fixed port can be occupied. `plan doctor` reports the owning process when possible and the service remains stopped until resolved.
- Markdown files edited outside the CLI may contain incomplete metadata. Reads normalize missing values in memory; explicit mutations write normalized frontmatter atomically.
- Filesystem watchers can coalesce or miss events during atomic editor saves or computer sleep. A periodic fingerprint rescan and revision check on event-stream reconnect provide recovery.
- LaunchAgent environments have a restricted `PATH`. The generated service configuration uses resolved executable paths for Node.js, Pandoc, and the repository command.
- A local web service can be targeted by hostile pages. Loopback binding, Host and Origin validation, no CORS, and CSRF protection limit that exposure.
- Hosted publication increases the exposure and operational cost of selected plans. Authentication, per-request authorization, private objects, sanitization, CSP, rate limits, explicit publishing, and documented deletion and retention controls reduce that risk.
- A push can upload a Blob object and fail before its database pointer commits. Versioned immutable keys and bounded orphan cleanup preserve the last visible revision.
- Two machines can push the same plan concurrently. Conditional hosted revisions reject the stale writer instead of silently selecting a winner.
- Existing global instruction files on another machine may contain local preferences. The linker preserves each conflict as a timestamped backup before installing the dotfiles-managed source.
- The application checkout can be missing, dirty, divergent, or configured with another origin. The bootstrap clones only a missing target, fast-forwards only a clean expected checkout, and otherwise preserves it while reporting the exact conflict.
- The current bare-worktree repository has no remote yet. Local planning can use its `main` worktree, but fresh-machine cloning remains blocked until a reachable origin or `PLAN_MANAGER_REPO_URL` is configured.
- A Codex application or organization permission profile can override local writable-root configuration. The installer preserves the safer policy, reports the limitation, and allows Codex to request approval rather than broadening access.
- Linking whole tool configuration directories would risk overwriting authentication and generated state. The installer links only the documented instruction files and leaves unrelated tool homes unmanaged.
- HTML-to-Markdown capture can lose presentation-only behavior. The captured Markdown is the durable source of truth, while the original HTML remains an unchanged derivative source artifact recorded in metadata.

## Migration Plan

1. Add a reachable origin to the `plan-manager` repository or set `PLAN_MANAGER_REPO_URL`.
2. Run `install/link.sh` to resolve or clone the application worktree, install locked dependencies, link the CLI, and install the shared skill, global instructions, client settings, and LaunchAgent.
3. Initialize `~/Developer/plans` and verify the health endpoint.
4. Start fresh sessions in each client, including a new Codex desktop task, so global instructions and skills reload.
5. Import each legacy Markdown plan explicitly and capture selected standalone HTML plans, preserving every source.
6. Verify each supported tool can invoke the portable workflow.
7. Optionally deploy and configure the hosted application, add it with `plan remote add`, authenticate through `plan auth login`, and explicitly push selected plans.

## Rollback

Unload and remove the LaunchAgent, restore the previous plan-browser output path, remove only symlinks owned by the installer, and restore timestamped instruction backups when desired. Removing the managed `~/.local/bin/plan` link does not delete the application repository or its worktrees. Remove a hosted remote and its keychain credential without deleting local Markdown. Hosted data deletion is an explicit authenticated operation governed by the hosted retention policy. Markdown under `~/Developer/plans` remains user data and is never deleted by rollback or uninstall.
