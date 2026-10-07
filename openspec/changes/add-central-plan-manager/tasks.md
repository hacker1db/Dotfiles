## 1. Core plan manager

- [x] 1.1 In the dedicated `plan-manager` repository, define the locked Node.js package, executable `bin/plan`, application layout, version command, and canonical metadata handling.
- [x] 1.2 Implement initialization, interactive new/edit, non-interactive create/update, import, list, search, show, status, archive, serve, and doctor commands.
- [x] 1.3 Add atomic writes, optimistic revision checks, path-containment checks, collision handling, versioned JSON envelopes, exit-code documentation, and non-TTY tests.
- [x] 1.4 Add an idempotent `plan capture` fallback that imports Markdown artifacts, converts standalone HTML artifacts to canonical Markdown through Pandoc, preserves external sources, normalizes unmanaged in-library Markdown, and updates an existing captured plan without changing its ID or URL.
- [x] 1.5 Migrate the application source to strict TypeScript, add shared typed plan-domain structures, compile to ignored runtime output, and make bootstrap run the pnpm build before linking the CLI.
- [x] 1.6 Add a pnpm TypeScript watch-mode development server that uses the canonical `plans.localhost` URL and verify it with an integration test.

## 2. Local dashboard

- [x] 2.1 Implement the loopback-only HTTP server, Markdown rendering, stable ID-based plan routes, API routes, and health endpoint.
- [x] 2.2 Build the responsive editorial dashboard with search, filters, rendering, status, archive, copy-path, editor actions, and same-route automatic refresh.
- [x] 2.3 Add debounced filesystem change detection, periodic fingerprint reconciliation, and a same-origin Server-Sent Events revision stream.
- [x] 2.4 Add Host, Origin, CORS, CSRF, malformed-file, fixed-port, stable-route, reconnect, and auto-refresh tests.
- [x] 2.5 Package the generated plan-document favicon with the local dashboard, declare it on library and detail pages, and verify its same-origin image route.

## 3. Tool integrations

- [x] 3.1 Create a concise shared `plans` skill with `references/cli.md`, `references/server.md`, `references/remote.md`, and realistic eval cases covering create, update, discovery, service recovery, explicit publishing, stable URLs, conflicts, and transient-plan exclusions.
- [x] 3.2 Add dotfiles-managed global instructions for Claude Code, OpenCode, Copilot, and Codex desktop/CLI, with the central workflow and transient-plan exclusions.
- [x] 3.3 Configure Claude Code's native `plansDirectory`, preserve its generated backend settings, and add Claude Code and OpenCode command adapters.
- [x] 3.4 Update `plan-browser` to write to the central library and open the dashboard.
- [x] 3.5 Run the shared skill evals and verify Claude Code, OpenCode, Copilot, and Codex desktop/CLI discovery through shared links in fresh sessions without overriding native planning modes or existing model configuration.
- [x] 3.6 Add a finalization guard to every supported harness: before returning a durable plan artifact, verify it has a plan-manager result and capture any unmanaged Markdown or HTML artifact regardless of where the harness wrote it.

## 4. Installation and service

- [x] 4.1 Add a safe `plan-manager` repository bootstrapper that supports the current `.bare` plus `main/` worktree layout, normal clones, explicit worktree and remote overrides, missing-target cloning, origin validation, clean fast-forward updates, and preservation of dirty, divergent, or conflicting targets.
- [x] 4.2 Install locked application dependencies, validate the repository-owned `bin/plan`, add `~/.local/bin` to shell `PATH`, and idempotently link `~/.local/bin/plan` without copying application code into dotfiles.
- [x] 4.3 Add an idempotent managed-file linker for Copilot and Codex global instructions, including timestamped backups for unmanaged conflicts and detection of a shadowing Codex global override.
- [x] 4.4 Add a format-aware, atomic Codex config reconciler that merges the resolved plan root into `sandbox_workspace_write.writable_roots` while preserving all unrelated settings and existing roots.
- [x] 4.5 Add LaunchAgent template generation from the resolved application worktree, atomic installation, load/reconcile logic, stable log paths, and uninstall guidance.
- [x] 4.6 Update `install/link.sh` to run repository bootstrap before linking client surfaces, reconcile Codex plan-library access, initialize `~/Developer/plans`, verify Node.js, pnpm, and Pandoc, and finish with `plan doctor`.
- [x] 4.7 Document application repository ownership, remote setup, normal and bare-worktree layouts, CLI usage, stable URL, per-tool invocation syntax, cross-machine bootstrap, fresh-session requirements, migration, troubleshooting, and rollback.

## 5. Verification

- [x] 5.1 Test from an absent plan directory, an existing valid directory, and a conflicting non-directory path.
- [x] 5.2 Import the existing Claude Markdown plan without modifying its source and verify it renders in the dashboard.
- [x] 5.3 Run `install/link.sh` twice and verify the second run is a no-op for managed links, Codex writable roots, settings, LaunchAgent state, and user data.
- [x] 5.4 Verify unmanaged instruction conflicts and the original Codex config are backed up, unrelated tool state and existing writable roots are preserved, and all supported adapters work in fresh sessions.
- [x] 5.5 Verify Codex desktop can create and update a managed plan from an unrelated repository without broadening its sandbox or approval policy, or reports a managed-policy approval requirement clearly.
- [x] 5.6 Open a plan detail page, update it through the CLI and an external editor, and verify the same URL reloads with the new content without reacting to unrelated plan changes.
- [x] 5.7 Disconnect and reconnect the event stream, simulate a missed watcher event, and verify revision reconciliation refreshes a stale page.
- [x] 5.8 Run shell syntax checks, CLI integration tests, UI browser checks, and strict OpenSpec validation.
- [x] 5.9 Verify a missing checkout clone, the current bare-worktree checkout, a normal clone, environment overrides, missing origin, unexpected origin, non-Git target, dirty and divergent worktrees, frozen dependency failure, broken CLI link repair, and repeated no-op linking without deleting or resetting repository data.
- [x] 5.10 Add executable contract and mock-finalization tests for Claude Code, Codex desktop/CLI, OpenCode, and Copilot that verify CLI delegation, the finalization guard, native planning-mode preservation, stable results, and installation of each harness's managed policy and shared skill.
- [x] 5.11 Verify Markdown capture, HTML-to-Markdown capture, unmanaged in-library Markdown normalization after lock waits, unchanged external sources, idempotent and concurrent recapture, mixed-command collision-free creation, one-winner optimistic updates, stale-lock and dead legacy recovery-guard handling with 30 concurrent writers, non-JSON CLI output, stable IDs and URLs after source changes, unsupported input rejection, and clear Pandoc dependency failures.

## 6. Optional hosted publishing

- [ ] 6.1 Build and deploy the repository-owned authenticated Next.js plan application with stable library and plan routes plus versioned Route Handlers for CLI publishing, revision checks, and Markdown download.
- [ ] 6.2 Provision private Vercel Blob for immutable Markdown objects and Marketplace Postgres for ownership, metadata, hashes, revisions, token records, search, retention, and orphan cleanup.
- [ ] 6.3 Implement browser sessions and revocable scoped CLI credentials, store local credentials in the macOS Keychain, and enforce authentication, ownership, rate, and size checks inside every hosted API handler.
- [ ] 6.4 Implement `plan remote`, `plan auth`, `plan push`, remote status, and remote open commands with versioned JSON output, conditional revisions, per-plan partial-success reporting, and no Vercel or storage credentials in the CLI.
- [ ] 6.5 Add sanitized hosted Markdown rendering, strict CSP, private authenticated downloads, cache invalidation, and same-route revision refresh after a successful push.
- [ ] 6.6 Verify explicit single and bulk publishing, exact Markdown retrieval, stable hosted URLs, cross-machine conflicts, revoked credentials, malformed and malicious uploads, partial storage failures, orphan cleanup, offline local operation, and removal of a remote without changing local plans.
