## Why

Plans are currently tied to individual AI tools and scattered across tool-specific directories. A single Markdown-first library and local dashboard will make plans discoverable and manageable regardless of which agent created them.

An optional hosted review surface will make selected plans available across machines without turning Vercel deployments or cloud storage into the canonical authoring workflow.

The plan-manager application and CLI now have a dedicated repository rooted at `~/Developer/sites/plan-manager`. Dotfiles should bootstrap and link that repository rather than owning a second copy of the application implementation.

## What Changes

- Add a tool-neutral `plan` CLI backed by `~/Developer/plans`.
- Keep the CLI, local server, hosted application, application dependencies, and tests in the separate `plan-manager` repository.
- Extend `install/link.sh` to discover an existing normal or bare-worktree checkout, clone the repository when missing, install locked dependencies, and link its `plan` executable onto `PATH` without replacing user data.
- Create the plan directory and required subdirectories when they are missing, while failing safely if the path is not a directory.
- Serve a centralized dashboard at `http://plans.localhost:4173/`, bound only to loopback.
- Give each plan a stable ID-based dashboard URL and automatically reload an open plan at that same URL whenever its canonical Markdown changes.
- Add an optional Vercel-hosted dashboard that is deployed once and receives selected plans through authenticated CLI uploads rather than creating a deployment per plan.
- Add remote configuration, authentication, and `plan push` commands that upload the canonical Markdown file and return its stable hosted URL while keeping local Markdown authoritative.
- Store hosted Markdown files in private Vercel Blob storage and searchable ownership, metadata, content hashes, and revisions in Marketplace Postgres.
- Install a macOS LaunchAgent so the dashboard starts at login and restarts after unexpected exits.
- Add a shared `plans` agent skill with CLI and local-server references, realistic eval cases, and native adapters for Claude Code, OpenCode, Copilot CLI, and Codex.
- Store every plan-policy and client-integration source in the dotfiles repository and make `install/link.sh` reconcile them into each tool's supported global location.
- Configure Codex desktop and CLI to load the shared plan policy and skill, and grant the canonical plan library as an additional workspace-write root without replacing unrelated Codex settings.
- Configure Claude Code's native plan directory through the existing generated-settings backend while preserving unrelated model, authentication, and status-line settings.
- Update the existing plan-browser workflow to save new plans into the central library.
- Copy existing Markdown plans into the library through an explicit migration, preserving their originals.
- Add an idempotent capture fallback and per-harness finalization guard so durable Markdown or HTML plan artifacts created outside the library are registered before a supported agent returns them.
- Build the plan-manager application from strict TypeScript, with typed canonical plan metadata, status values, JSON envelopes, and CLI options.

## Impact

- Affected specs: `plan-management`
- Application repository: `~/Developer/sites/plan-manager`, containing the CLI, local server, hosted application, database migrations, and application tests
- Affected dotfiles code: repository bootstrap configuration, `install/link.sh`, shell `PATH`, LaunchAgent integration, tool-specific instruction sources, `claude/skills/`, `codex/`, client command adapters, and `claude/output-styles/plan-browser.md`
- Local runtime dependencies: existing Node.js, pnpm, TypeScript build tooling, and Pandoc installations
- Optional hosted dependencies: Vercel, Next.js Route Handlers, private Vercel Blob storage, Marketplace Postgres, and an application authentication provider
- User data: new files under `~/Developer/plans`; existing plan files remain unchanged
- Hosted data: only plans explicitly pushed through the CLI, with local Markdown remaining canonical
- Machine setup: rerunning `install/link.sh` becomes the supported way to install or repair the plan manager on each Mac
- Repository prerequisite: the created repository needs a reachable Git remote before a fresh machine can clone it; `PLAN_MANAGER_REPO_URL` remains an explicit override
