## ADDED Requirements

### Requirement: Canonical Markdown Plan Library

The system SHALL use `~/Developer/plans` as the canonical plan library and SHALL keep Markdown files as the source of truth.

#### Scenario: Missing library

- **WHEN** a plan command runs and `~/Developer/plans` does not exist
- **THEN** the system creates the library and its required subdirectories before continuing

#### Scenario: Invalid library path

- **WHEN** the configured plan path exists but is not a directory
- **THEN** the system exits with a clear error without modifying that path

#### Scenario: Existing Markdown import

- **WHEN** the user imports an existing Markdown file
- **THEN** the system copies it into the library with normalized plan metadata and leaves the original unchanged

#### Scenario: Standalone artifact capture

- **WHEN** a supported harness produces a durable plan as Markdown or standalone HTML outside the canonical library
- **THEN** the system captures it as canonical Markdown, records the original source path, leaves the source unchanged, and returns a stable plan ID and dashboard URL

#### Scenario: Idempotent artifact recapture

- **WHEN** a previously captured source artifact is captured again
- **THEN** the system updates the existing canonical plan only when its converted content changed and retains the same plan ID and dashboard URL

#### Scenario: Unmanaged Markdown inside the library

- **WHEN** a native harness writes durable Markdown into `~/Developer/plans` without plan-manager metadata
- **THEN** explicit capture normalizes that file in place with stable metadata so the dashboard can index it

#### Scenario: Concurrent artifact capture

- **WHEN** multiple harness processes capture the same source or different sources with the same inferred title concurrently
- **THEN** the system serializes capture registration, returns one stable plan for the same source, and preserves distinct plans without overwriting either source

#### Scenario: Unsupported artifact capture

- **WHEN** a caller attempts to capture an unsupported file type or HTML conversion is unavailable
- **THEN** the system exits with a clear error and does not create or modify a canonical plan

### Requirement: Portable Plan Command

The system SHALL provide a `plan` executable on `PATH` whose storage and serving behavior is independent of any AI tool.

#### Scenario: Invocation from any tool

- **WHEN** Claude Code, OpenCode, Copilot, Codex, or a terminal invokes the `plan` executable with the same arguments
- **THEN** the command produces the same behavior and operates on the same canonical library

#### Scenario: Machine-readable listing

- **WHEN** a caller runs `plan list --json` or `plan search <query> --json`
- **THEN** the command returns stable structured output suitable for agent use

#### Scenario: Non-interactive plan creation

- **WHEN** an agent supplies complete Markdown to `plan create` through standard input or a file
- **THEN** the command creates the canonical plan without opening an editor and returns a versioned JSON result containing its ID, path, stable dashboard URL, and revision

### Requirement: Typed Application Build

The system SHALL compile plan-manager application code with strict TypeScript checks before its CLI is linked or used as the installed runtime.

#### Scenario: Closed plan-domain values

- **WHEN** code constructs plan metadata or a JSON envelope
- **THEN** shared TypeScript structures enforce the required fields and accept only `active`, `completed`, or `archived` as plan statuses

#### Scenario: Machine bootstrap

- **WHEN** the dotfiles installer provisions the plan-manager CLI
- **THEN** it runs `pnpm install --frozen-lockfile` followed by `pnpm build`, and it leaves the existing CLI link untouched when either step fails

### Requirement: Canonical Development URL

The system SHALL provide a pnpm development server that uses the same loopback-bound `plans.localhost` URL as the installed dashboard.

#### Scenario: TypeScript development server

- **WHEN** a developer runs `pnpm dev`
- **THEN** the source watcher serves the dashboard at `http://plans.localhost:4173` by default and reflects TypeScript source changes without switching to a raw loopback browser URL

#### Scenario: Local favicon

- **WHEN** a browser loads the local library or plan detail page
- **THEN** the document declares the packaged `/icon.png` favicon and the same-origin route returns a PNG image

#### Scenario: Revision-aware plan update

- **WHEN** an agent supplies complete Markdown and the current revision to `plan update`
- **THEN** the command updates the canonical plan and returns its unchanged ID and stable dashboard URL, or rejects the operation as a conflict if the revision is stale

#### Scenario: Ambiguous identifier

- **WHEN** an identifier matches more than one plan
- **THEN** the command reports the candidates and does not mutate any plan

#### Scenario: Concurrent plan creation

- **WHEN** multiple harness processes create, import, or capture plans with colliding titles concurrently
- **THEN** the system serializes registration and preserves every distinct plan with a unique ID and path

#### Scenario: Concurrent optimistic update

- **WHEN** multiple writers update one plan using the same current revision
- **THEN** exactly one update succeeds and every later writer receives a stale-revision conflict without overwriting the winner

### Requirement: Central Local Dashboard

The system SHALL serve all managed plans from `http://plans.localhost:4173/` and SHALL bind the service only to loopback.

#### Scenario: Automatic startup

- **WHEN** the user logs into macOS
- **THEN** the LaunchAgent starts the plan service and keeps it available at the stable local address

#### Scenario: Dashboard use

- **WHEN** the user opens the dashboard
- **THEN** the user can search, filter, render, change status, archive, copy a path, and open a plan in the configured editor

#### Scenario: Offline use

- **WHEN** the computer has no internet connection
- **THEN** the dashboard remains fully styled and functional

#### Scenario: Port collision

- **WHEN** another process occupies port 4173
- **THEN** the plan service reports the collision and does not select a different address

### Requirement: Safe Local Web Mutations

The local server MUST validate every request before reading or changing plan files.

#### Scenario: External-origin mutation

- **WHEN** a mutating request has an unexpected Host, Origin, or CSRF token
- **THEN** the server rejects it without changing any file

#### Scenario: Path traversal attempt

- **WHEN** a request resolves outside `~/Developer/plans`
- **THEN** the server rejects it without reading or changing the target

#### Scenario: Atomic metadata update

- **WHEN** a status or archive operation succeeds
- **THEN** the resulting Markdown and metadata are complete and no partial file is observable

#### Scenario: Shared mutation serialization

- **WHEN** CLI and dashboard mutations overlap
- **THEN** they use the same library writer lock so revision checks, metadata changes, and archive moves cannot overwrite one another

#### Scenario: Ownership-safe stale-lock recovery

- **WHEN** many writers encounter a lock left by a crashed process
- **THEN** an atomic lease-backed lock serializes them, stale ownership is reclaimed without removing an active successor's lock, and a dead legacy recovery guard cannot block future mutations

### Requirement: Live Same-Page Plan Refresh

The system SHALL give each plan a stable ID-based dashboard URL and SHALL automatically refresh an open plan at that same URL after its canonical Markdown changes.

#### Scenario: Plan updated by a tool

- **WHEN** the open plan is updated through the `plan` CLI, a supported agent adapter, or a dashboard action
- **THEN** the browser reloads the current plan URL and renders the updated Markdown

#### Scenario: Plan updated by an external editor

- **WHEN** an external editor saves changes to the open plan under the canonical library
- **THEN** the server detects the stable file revision and the browser reloads the same plan URL with the new content

#### Scenario: Stable URL across metadata changes

- **WHEN** a plan title, filename, status, or archive location changes
- **THEN** its immutable ID-based dashboard URL remains valid and resolves the updated plan

#### Scenario: Unrelated plan update

- **WHEN** a different plan changes while a plan detail page is open
- **THEN** the open detail page is not reloaded or navigated away

#### Scenario: Event stream recovery

- **WHEN** the browser reconnects after the change stream was interrupted or the computer woke from sleep
- **THEN** it compares revisions and reloads the same URL if the open plan became stale

#### Scenario: Partial external write

- **WHEN** an external save temporarily exposes an incomplete or changing file
- **THEN** the server waits for a stable debounced fingerprint and does not create a repeated reload loop

### Requirement: Native Agent Adapters

The system SHALL expose a thin `plans` adapter in Claude Code, OpenCode, Copilot, and Codex desktop/CLI while keeping the `plan` executable authoritative.

#### Scenario: Supported client invocation

- **WHEN** a user invokes `/plans` in Claude Code, OpenCode, or Copilot, or `$plans` in Codex desktop or CLI
- **THEN** the adapter delegates the request to the portable `plan` executable

#### Scenario: Built-in plan mode preservation

- **WHEN** a user invokes the built-in `/plan` command in Codex or Copilot
- **THEN** the client retains its native planning-mode behavior without being overridden by the plan manager

### Requirement: Shared Plan Skill Contract

The system SHALL provide one tool-neutral `plans` skill that teaches supported agents when and how to use the authoritative CLI and local dashboard without duplicating their implementation.

#### Scenario: Durable plan operation

- **WHEN** a user asks an agent to create, save, update, find, review, open, complete, or archive a user-facing plan
- **THEN** the skill delegates the operation to the `plan` CLI in non-interactive mode and returns the resulting plan ID and stable dashboard URL

#### Scenario: Local service unavailable

- **WHEN** a requested plan must be opened or reviewed and the local dashboard is not running
- **THEN** the skill uses `plan serve` and `plan doctor` to recover or diagnose the service instead of starting an independent server

#### Scenario: Transient internal planning

- **WHEN** an agent creates transient reasoning or a short internal task list that is not a user-facing deliverable
- **THEN** the skill does not persist it to the canonical plan library

#### Scenario: Skill operation failure

- **WHEN** the CLI cannot persist a plan or make the local dashboard healthy
- **THEN** the skill reports the failure and does not claim that a plan was saved or that its dashboard URL is available

#### Scenario: Harness finalization guard

- **WHEN** Claude Code, Codex, OpenCode, or Copilot created a durable user-facing plan artifact without a successful plan-manager result
- **THEN** its managed policy invokes `plan capture <artifact> --json` before the final response and reports the returned plan ID and stable dashboard URL

### Requirement: Reproducible Dotfiles Configuration

The system SHALL keep plan-management instructions and supported client settings in the dotfiles repository and SHALL install them through `install/link.sh`.

#### Scenario: Fresh-machine bootstrap

- **WHEN** the user clones the dotfiles repository on a Mac and runs `install/link.sh`
- **THEN** the installer resolves or clones the separate plan-manager repository, links its CLI, and gives Claude Code, OpenCode, Copilot, and Codex desktop/CLI the central plan instructions and shared skill through their supported global locations

#### Scenario: Codex global guidance reload

- **WHEN** linking completes and the user starts a new Codex desktop task or CLI session
- **THEN** Codex loads the central plan policy and can discover the shared `plans` skill

#### Scenario: Codex global override shadows policy

- **WHEN** a non-empty `~/.codex/AGENTS.override.md` would shadow the managed global guidance
- **THEN** installation or `plan doctor` reports the conflict and does not claim that Codex is configured successfully

#### Scenario: Codex plan-library permission

- **WHEN** `install/link.sh` configures Codex on a machine
- **THEN** it merges the resolved `~/Developer/plans` path into `sandbox_workspace_write.writable_roots` without forcing a sandbox mode or approval policy

#### Scenario: Codex config preservation

- **WHEN** the existing Codex config contains other writable roots or unrelated settings
- **THEN** reconciliation preserves them, creates a backup before its first mutation, and changes only the documented plan-library permission

#### Scenario: Managed Codex permission override

- **WHEN** an application or organization policy prevents the configured plan root from being writable
- **THEN** Codex requests approval when supported and `plan doctor` reports the effective-access limitation without weakening the managed policy

#### Scenario: Claude native plan storage

- **WHEN** Claude Code enters plan mode after linking
- **THEN** its native plan file is written under `~/Developer/plans` through the dotfiles-managed `plansDirectory` setting

#### Scenario: Repeated linking

- **WHEN** the user reruns `install/link.sh` without changing the managed sources
- **THEN** the command leaves correct links, tool state, plan data, and service state unchanged and exits successfully

#### Scenario: Unmanaged instruction conflict

- **WHEN** a managed destination contains an unmanaged regular file
- **THEN** the linker creates a timestamped same-directory backup before installing the dotfiles-managed symlink

#### Scenario: Existing tool state

- **WHEN** a supported tool already has authentication, model, plugin, session, memory, cache, or permission state
- **THEN** the linker preserves unrelated state and modifies only the documented plan-management instruction and Codex plan-library permission surfaces

#### Scenario: Machine-specific service paths

- **WHEN** the LaunchAgent is installed on a machine with a different home or Homebrew prefix
- **THEN** the linker resolves that machine's paths without committing a username or assuming a fixed package-manager prefix

### Requirement: Separate Application Repository Bootstrap

The system SHALL keep plan-manager application code in a dedicated Git repository under `~/Developer/sites/plan-manager` and SHALL use dotfiles only to bootstrap, link, and configure it.

#### Scenario: Missing application checkout

- **WHEN** the target repository is absent and an explicit or authenticated default repository URL is available
- **THEN** `install/link.sh` creates only the parent directory, clones the repository, and validates its worktree before continuing

#### Scenario: Missing repository URL

- **WHEN** the target repository is absent and neither `PLAN_MANAGER_REPO_URL` nor an authenticated default GitHub identity is available
- **THEN** installation reports that cloning is unavailable and does not invent a remote or create a partial checkout

#### Scenario: Normal repository checkout

- **WHEN** `~/Developer/sites/plan-manager` is a valid normal Git worktree
- **THEN** the installer uses that root as the application worktree

#### Scenario: Bare repository with linked main worktree

- **WHEN** the repository root contains the supported `.bare` layout and a valid `main/` linked worktree
- **THEN** the installer resolves `main/` as the application worktree without replacing the bare repository

#### Scenario: Explicit worktree override

- **WHEN** `PLAN_MANAGER_WORKTREE` identifies a valid worktree belonging to the configured repository
- **THEN** the installer uses that worktree for dependencies, CLI linking, service generation, and health checks

#### Scenario: Conflicting target

- **WHEN** the repository target exists but is not a supported Git repository or worktree layout
- **THEN** installation fails visibly without deleting, moving, or replacing the target

#### Scenario: Unexpected origin

- **WHEN** an existing checkout has an origin different from the configured plan-manager repository
- **THEN** installation preserves the checkout and requires explicit user resolution instead of fetching, resetting, or relinking from it

#### Scenario: Dirty or divergent checkout

- **WHEN** the resolved worktree has local changes or cannot be updated by fast-forward
- **THEN** installation preserves its branch, index, working files, and commits and reports the manual action required

#### Scenario: Repository dependency installation

- **WHEN** the resolved worktree contains the required package manifest and lockfile
- **THEN** installation performs a frozen dependency install and does not silently rewrite the lockfile

#### Scenario: Managed CLI link

- **WHEN** the repository-owned `bin/plan` passes executable and version checks
- **THEN** installation idempotently links it to `~/.local/bin/plan` and ensures that directory is on shell `PATH`

#### Scenario: Invalid repository CLI

- **WHEN** the expected executable is missing, non-executable, or fails its version check
- **THEN** installation does not replace a working managed CLI link and reports the repository validation failure

#### Scenario: Repeated repository bootstrap

- **WHEN** the repository, dependencies, and CLI link are already correct
- **THEN** rerunning `install/link.sh` leaves the checkout, lockfile, worktrees, and link targets unchanged and returns success

### Requirement: Optional Hosted Plan Publishing

The system SHALL allow the user to explicitly publish selected canonical Markdown plans to one authenticated Vercel-hosted plan application while keeping the local Markdown library authoritative.

#### Scenario: Hosted remote configuration

- **WHEN** the user adds a named hosted plan service
- **THEN** the CLI stores its base URL and non-secret synchronization state separately from plan Markdown and dotfiles-managed configuration

#### Scenario: Authenticated plan upload

- **WHEN** an authenticated user runs `plan push` for a valid plan
- **THEN** the CLI uploads the canonical Markdown bytes and metadata to the configured service and returns the unchanged plan ID, hosted revision, content hash, and stable authenticated URL

#### Scenario: No per-plan deployment

- **WHEN** a plan is pushed or updated
- **THEN** the system changes application data through the hosted API without creating a Vercel deployment, project, or static site for that plan

#### Scenario: Private hosted storage

- **WHEN** the hosted service accepts a plan
- **THEN** it stores the Markdown as an immutable private object and stores searchable ownership, metadata, object location, content hash, and revision records in transactional persistent storage

#### Scenario: Stale hosted revision

- **WHEN** a push presents a hosted revision older than the current remote revision
- **THEN** the service rejects the push as a conflict without replacing the visible hosted plan or modifying local Markdown

#### Scenario: Hosted service failure

- **WHEN** network, authentication, application, database, or object-storage failure prevents publishing
- **THEN** the CLI reports that the hosted copy was not updated while the canonical local Markdown and local dashboard remain available

#### Scenario: Hosted Markdown download

- **WHEN** an authorized user downloads a hosted plan
- **THEN** the application returns the exact published Markdown as `text/markdown` without exposing a public object-storage URL

#### Scenario: Safe hosted rendering

- **WHEN** an authorized user views a hosted plan containing raw HTML, active content, inline event handlers, or unsafe URL schemes
- **THEN** the application removes or rejects the unsafe content and renders the remaining Markdown under a strict Content Security Policy

#### Scenario: Hosted same-page refresh

- **WHEN** a newer revision is pushed while its authenticated hosted detail page is open
- **THEN** the browser detects the revision change and refreshes the same stable plan route

#### Scenario: Explicit publishing boundary

- **WHEN** a plan is created or updated without an explicit publish request or previously configured user policy
- **THEN** neither the CLI nor an agent adapter uploads it to a hosted service

#### Scenario: Hosted credential isolation

- **WHEN** the CLI authenticates to a hosted service
- **THEN** it stores only a revocable scoped application credential in the operating-system keychain and never receives Vercel, database, Blob, or deployment credentials

#### Scenario: Remote removal

- **WHEN** the user removes a hosted remote or logs out
- **THEN** the CLI removes its synchronization state or credential without deleting or changing canonical local plans

### Requirement: Legacy Workflow Migration

The system SHALL redirect future plan-browser output to the canonical library without deleting legacy plans.

#### Scenario: New generated plan

- **WHEN** the plan-browser workflow creates a user-facing plan
- **THEN** it saves the Markdown under `~/Developer/plans` and opens the centralized dashboard

#### Scenario: Legacy plan migration

- **WHEN** the user imports a file from `~/.claude/plans`
- **THEN** the imported copy appears in the dashboard and the legacy source remains unchanged
