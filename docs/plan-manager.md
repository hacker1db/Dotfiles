# Plan Manager

A tool-neutral local plan library backed by `~/notes/SecondBrain/4.Resources/plans`, served at `http://plans.localhost:4173/`, and accessible from Claude Code, OpenCode, Copilot, and Codex through the shared `plans` skill.

## Application repository

The plan-manager application — CLI, local server, dashboard, hosted Next.js app, migrations, and tests — lives in a dedicated Git repository separate from dotfiles:

- Default location: `~/Developer/plan-manager`
- Override: set `PLAN_MANAGER_REPO_DIR` before running `install/link.sh`

Dotfiles owns the bootstrap configuration, CLI symlink, LaunchAgent template, global instructions, and command adapters. The shared `plans` skill, including its contract and evals, lives in the skills repository. Application code is never copied into dotfiles.

### Repository layouts

`install/link.sh` supports three checkout layouts at the target root:

| Layout | Description | Resolved worktree |
| --- | --- | --- |
| Normal clone | Standard `git clone` | `~/Developer/plan-manager` |
| Bare + linked worktree | `.bare` dir + `main/` linked worktree | `~/Developer/plan-manager/main` |
| Explicit override | `PLAN_MANAGER_WORKTREE` set | Value of that variable |

Fresh clones created by the bootstrap use a normal clone. Existing bare repositories with a `main/` worktree are supported.

The following overrides are supported:

- `PLAN_MANAGER_REPO_DIR`: repository container or normal-clone path
- `PLAN_MANAGER_WORKTREE`: an explicit worktree that must belong to the configured repository
- `PLAN_MANAGER_REPO_URL`: the expected origin and clone URL
- `PLAN_HOME`: canonical plan-library path, defaulting to `~/notes/SecondBrain/4.Resources/plans`

### Remote setup

Before cross-machine bootstrap can work, the repository needs a reachable origin:

```bash
# Add the remote (inside the application worktree)
cd ~/Developer/plan-manager/main
git remote add origin git@github.com:<your-user>/plan-manager.git
git push -u origin main
```

Or set the override before running the installer on a fresh machine:

```bash
PLAN_MANAGER_REPO_URL=git@github.com:<your-user>/plan-manager.git install/link.sh
```

If neither an explicit URL nor an authenticated `gh` identity is available, `install/link.sh` skips cloning and reports the limitation clearly.

Existing checkouts are never reset, cleaned, stashed, or branch-switched. An
unexpected origin stops plan-manager installation. Dirty, ahead, or divergent
worktrees are preserved and reported for manual review; only a clean checkout
with a validated origin and upstream may be fast-forwarded.

## Bootstrap and installation

```bash
# On any Mac after cloning dotfiles
cd ~/.dotfiles/main
install/link.sh
```

The installer:

1. Resolves or clones the plan-manager repository.
2. Builds the selected checkout's Go package from `cli/` using a private staged `GOBIN` and `go install -mod=readonly ./cmd/plan` (`GOWORK=off`, ignoring ambient `GOFLAGS`). Go enforces the toolchain requirement in `cli/go.mod`; missing Go sources stop installation.
3. Validates Go module/package build identity, version, and Zsh completions, then atomically promotes the binary to `~/.local/lib/plan-manager/plan` and links `~/.local/bin/plan` to it. Failed builds or validation leave the previous command usable.
4. Links global instructions and command adapters. Install the `plans` skill separately through skillctl.
5. Merges `~/notes/SecondBrain/4.Resources/plans` into the Codex writable-root config.
6. Initializes `~/notes/SecondBrain/4.Resources/plans` and its `archive/` subdirectory only if the vault folder already exists; it never creates the folder.
7. Installs the LaunchAgent and loads it with `launchctl`.
8. Runs `plan serve --json` and `plan doctor --json`, reporting failures (skipped when the vault folder is missing).

The bootstrap preserves correct managed links and backs up replaced files. Rerunning can fetch and fast-forward the application checkout, rebuild the Go CLI, and check/start the service. It is not a no-op verification command. A plan-manager failure is reported after other dotfiles links have been attempted and makes the linker exit nonzero.

The Codex reconciler creates `~/.codex/config.toml` when absent. Before changing
an existing file it writes a timestamped same-directory backup, then atomically
adds the plan root to the existing `sandbox_workspace_write.writable_roots`
array without setting a sandbox mode or approval policy.

### Prerequisites

- macOS
- Go satisfying `cli/go.mod` (Go may download the required toolchain)
- Node.js for the LaunchAgent renderer and Codex configuration reconciler; the full dotfiles installer also requires Node.js ≥ 20 and pnpm for other tools
- `lsof` for dashboard executable verification
- Pandoc (verified before service installation)
- `gh` CLI authenticated (only needed to derive the default clone URL)

## CLI usage

The `plan` executable is linked at `~/.local/bin/plan` after installation. Dotfiles Zsh startup deduplicates `PATH` and puts that directory first after tool initialization, then loads completions from the selected command. pnpm global commands remain available. Explicit user aliases and functions are preserved and reported by the installer diagnostic.

The bootstrap and LaunchAgent explicitly pass `PLAN_HOME=~/notes/SecondBrain/4.Resources/plans`. The application can have a different default, and the symlink does not set environment variables. For terminal invocations, set the canonical root in `~/.localrc` and reload the shell:

```sh
export PLAN_HOME="$HOME/notes/SecondBrain/4.Resources/plans"
```

Confirm the effective root with `plan doctor --json` before creating or importing plans. Agent operations use non-interactive JSON mode; opening/reviewing requires `plan serve` and `plan doctor --json` first.

Bare `plan` opens the dashboard. `plan list` prints the styled list when stdout is a terminal, and plain text when piped; `plan list --json` preserves automation output. `plan tui` opens the interactive terminal manager. Installing an individual Go source file may create `~/go/bin/main`; use the package command above to get a binary named `plan`. The installer leaves unrelated commands, including `~/go/bin/main` and pnpm wrappers, intact.

### Common operations

```bash
# Create a plan (interactive)
plan new "My Project Plan"

# Create non-interactively (agent/script use)
printf '# My Plan\n\nSteps here.\n' | plan create --title "My Plan" --stdin --json

# Capture a Markdown or standalone HTML plan created by a harness
plan capture /path/to/plan.html --json

# List all plans
plan list --json

# Search
plan search "migration" --json

# Show a plan
plan show <id-or-slug> --json

# Update with revision guard (agent/script use)
echo "# Updated content" | plan update <id> --stdin --if-revision <sha256-revision> --json

# Change status
plan status <id> completed

# Archive
plan archive <id>

# Open dashboard
plan open

# Open a specific plan in the dashboard
plan open <id-or-slug>

# Health check
plan doctor --json
```

Use `plan --help` and the application repository README for the installed CLI contract. The legacy skill references in dotfiles may describe an older application release.

## Stable local dashboard URL

```text
http://plans.localhost:4173/
```

Each plan has a stable ID-based route:

```text
http://plans.localhost:4173/plans/<id>
```

The ID is immutable across title changes, renames, status changes, and archive moves.

## Default publication behavior

After each successful user-facing plan mutation, harnesses run `plan push <id> --json` and return the hosted URL confirmed by the response from `https://planmanager.hacker1db.dev`. The local dashboard remains available for local use, but agents do not return or prefer its URL unless the user explicitly requests local-only handling.

If a push fails, the canonical vault plan remains intact. Report its absolute path and the push failure without inventing a hosted URL or substituting the localhost route.

## Per-tool invocation

| Tool | Command | Notes |
| --- | --- | --- |
| Claude Code | `/plans` | Delegates to the `plans` skill |
| OpenCode | `/plans` | Delegates to the `plans` skill |
| Copilot CLI | `/plans` | Delegates to the `plans` skill |
| Codex desktop | `$plans` or `/skills` → plans | Preserves native `/plan` mode |
| Codex CLI | `$plans` | Preserves native `/plan` mode |
| Terminal | `plan <command>` | Direct CLI access |

## Fresh-session requirements

After `install/link.sh` completes:

- **Claude Code, OpenCode, Copilot**: start a new session to pick up updated instructions and command adapters; ensure the shared skill is installed separately.
- **Codex desktop**: global guidance loads once at the beginning of a run; start a new desktop task after linking.
- **Codex CLI**: start a new CLI session after linking.

The LaunchAgent starts the dashboard service automatically at login. If the service is not running, `plan serve` starts it.

The generated LaunchAgent is installed at
`~/Library/LaunchAgents/com.plan-manager.serve.plist`. Its resolved home,
worktree, executable, plan root, and runtime `PATH` are machine-specific and are
not committed to dotfiles. A binary content hash in the agent environment forces unload/reload when the installed Go binary changes, even when the paths stay the same. Node is used to render the plist; the Go dashboard serves its embedded assets and needs Pandoc for rendering. The installer checks the listener executable and canonical library health. Logs remain at:

- `~/Library/Logs/plan-manager/serve.log`
- `~/Library/Logs/plan-manager/serve.error.log`

## Migration from legacy plan locations

Existing Markdown plans under `~/.claude/plans/` are not migrated automatically. Import them explicitly to preserve originals:

```bash
# Import one plan
plan import ~/.claude/plans/my-plan.md

# Import all plans
for f in ~/.claude/plans/*.md; do plan import "$f"; done
```

The source file is never modified or deleted. The imported copy appears in the dashboard at its stable ID-based URL.

Standalone Markdown or HTML artifacts created by Claude Code, Codex, OpenCode, or Copilot can be registered explicitly:

```bash
plan capture ~/.codex/visualizations/<task>/implementation-plan.html --json
```

HTML capture uses Pandoc to create canonical GitHub-flavored Markdown. External artifacts remain unchanged and are recorded as the plan's source. Unmanaged Markdown already written inside `~/notes/SecondBrain/4.Resources/plans` is normalized in place with plan-manager metadata. Capturing the same absolute source again updates the existing managed plan only when its converted content changed, preserving its ID and stable dashboard URL. All CLI and dashboard mutations share a bounded writer lock so identical sources converge on one plan, equal-title operations do not overwrite each other, and concurrent revision-guarded updates produce one winner. The dashboard does not crawl tool-specific artifact directories.

## Hosted publishing (optional)

Hosted publishing is opt-in and must be explicitly requested. Local Markdown remains authoritative. The application now supports a single hosted site, configured through `PLAN_MANAGER_URL`; the earlier named-remote commands are not the current workflow.

```sh
plan auth login
plan auth status
plan push <id> --json
```

Use the application repository's README and `docs/hosting.md` for authentication, revision conflicts, and deployment setup. This dotfiles bootstrap does not deploy the hosted service or authenticate an account. It does not publish plans during installation.

## Troubleshooting

### Dashboard not reachable

```bash
plan doctor --json
```

Common causes:

- Service not started: `plan serve` to start it.
- Port 4173 occupied: `plan doctor` reports the owning process. Resolve the collision, then `plan serve`.
- LaunchAgent not loaded: `launchctl list | grep plan-manager` to check; rerun `install/link.sh` to reinstall.

### `plan: command not found`

`~/.local/bin` is not on `PATH`. Add it in `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload: `source ~/.zshrc; rehash`, or open a fresh terminal. Rerun `install/link.sh` only if the CLI symlink needs repair; its environment changes do not modify the parent shell.

### Wrong implementation or stale completions

```sh
type -a plan
whence -w plan
go version -m "$HOME/.local/bin/plan"
plan completion zsh
```

Expect `~/.local/bin/plan` first and package identity `github.com/hacker1db/plan-manager/cli/cmd/plan` with module `github.com/hacker1db/plan-manager/cli`. Versions alone do not distinguish Go and TypeScript. Reload Zsh and run `rehash` after updating dotfiles. Inspect user aliases/functions if the diagnostic still reports a different selection. The Go default requires the selected main checkout to contain `cli/go.mod` and `cli/cmd/plan/main.go`; the installer never silently changes branches or falls back to TypeScript.

### Codex cannot write to `~/notes/SecondBrain/4.Resources/plans`

Check `~/.codex/config.toml` for `sandbox_workspace_write.writable_roots`. If a managed application or organization policy overrides local settings, Codex will request approval — approve it when prompted. `plan doctor` reports this as an effective-access limitation.

### `~/.codex/AGENTS.override.md` shadows policy

A non-empty `AGENTS.override.md` takes precedence over `~/.codex/AGENTS.md`. `plan doctor` reports this conflict. Resolve by removing or merging the override file, then start a new Codex session.

### Stale Codex session

Codex loads global guidance once per run. If plan policy changes are not reflected, start a new desktop task or CLI session.

## Rollback

Restore `~/.local/lib/plan-manager/plan.backup-<timestamp>` over the managed binary, or restore the backed up `~/.local/bin/plan.backup-<timestamp>` link for the prior TypeScript installation. Revert the Zsh changes, reload with `source ~/.zshrc; rehash`, then reload the previous LaunchAgent and verify executable identity and health. Binary and link backups are retained by the installer.


```bash
# Unload and remove the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.plan-manager.serve.plist
rm ~/Library/LaunchAgents/com.plan-manager.serve.plist

# Remove the CLI symlink (does not touch the application repo)
rm ~/.local/bin/plan

# Restore a backed-up instruction file (example)
mv ~/.codex/AGENTS.md.backup-<timestamp> ~/.codex/AGENTS.md

# Clear hosted authentication without deleting local plans
plan auth logout
```

Removing the `~/.local/bin/plan` symlink does not delete `~/Developer/plan-manager` or its worktrees. Markdown files under `~/notes/SecondBrain/4.Resources/plans` are user data and are never deleted by rollback or uninstall.

## Installer verification

Run the isolated installer checks without touching live tool configuration or
loading a LaunchAgent:

```bash
~/.dotfiles/main/install/tests/plan-manager-bootstrap.test.sh
```

The checks cover current bare-worktree resolution, explicit-worktree
validation, normal-clone/bare/override builds, missing Go/sources, build and
validation failure preservation, private staging, TypeScript link migration,
instruction backups, atomic Codex config reconciliation, and binary-triggered
LaunchAgent reconciliation under a temporary `HOME`.

Run `bash install/tests/plan-manager-zsh.test.sh` for fresh-shell selection and
completion checks with legacy pnpm wrappers, duplicate PATH entries, and spaces.

To undo an output-style change, inspect its Git history and restore the intended revision of `claude/output-styles/plan-browser.md`; do not assume the previous commit contains the desired version.
