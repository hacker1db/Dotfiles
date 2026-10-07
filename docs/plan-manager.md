# Plan Manager

A tool-neutral local plan library backed by `~/Developer/plans`, served at `http://plans.localhost:4173/`, and accessible from Claude Code, OpenCode, Copilot, and Codex through the shared `plans` skill.

## Application repository

The plan-manager application — CLI, local server, dashboard, hosted Next.js app, migrations, and tests — lives in a dedicated Git repository separate from dotfiles:

- Default location: `~/Developer/sites/plan-manager`
- Override: set `PLAN_MANAGER_REPO_DIR` before running `install/link.sh`

Dotfiles owns only the bootstrap configuration, CLI symlink, LaunchAgent template, skill, global instructions, and command adapters. Application code is never copied into dotfiles.

### Repository layouts

`install/link.sh` supports three checkout layouts at the target root:

| Layout | Description | Resolved worktree |
|---|---|---|
| Normal clone | Standard `git clone` | `~/Developer/sites/plan-manager` |
| Bare + linked worktree | `.bare` dir + `main/` linked worktree | `~/Developer/sites/plan-manager/main` |
| Explicit override | `PLAN_MANAGER_WORKTREE` set | Value of that variable |

The current machine uses the **bare + linked worktree** layout. Fresh machines receive a normal clone.

The following overrides are supported:

- `PLAN_MANAGER_REPO_DIR`: repository container or normal-clone path
- `PLAN_MANAGER_WORKTREE`: an explicit worktree that must belong to the configured repository
- `PLAN_MANAGER_REPO_URL`: the expected origin and clone URL
- `PLAN_HOME`: canonical plan-library path, defaulting to `~/Developer/plans`

### Remote setup

Before cross-machine bootstrap can work, the repository needs a reachable origin:

```bash
# Add the remote (inside the application worktree)
cd ~/Developer/sites/plan-manager/main
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
cd ~/.dotfiles
install/link.sh
```

The installer:

1. Resolves or clones the plan-manager repository.
2. Installs locked application dependencies (`pnpm install --frozen-lockfile`).
3. Validates `bin/plan` and links it to `~/.local/bin/plan`.
4. Links the shared skill, global instructions, and command adapters.
5. Merges `~/Developer/plans` into the Codex writable-root config.
6. Installs the LaunchAgent and loads it with `launchctl`.
7. Initializes `~/Developer/plans` and its `archive/` subdirectory.
8. Runs `plan doctor` to confirm everything is healthy.

`install/link.sh` is idempotent: a second run with unchanged sources leaves all links, tool state, plan data, and service state unchanged.

The Codex reconciler creates `~/.codex/config.toml` when absent. Before changing
an existing file it writes a timestamped same-directory backup, then atomically
adds the plan root to the existing `sandbox_workspace_write.writable_roots`
array without setting a sandbox mode or approval policy.

### Prerequisites

- macOS
- Node.js ≥ 20 (verified at install time)
- pnpm (verified at install time)
- Pandoc (verified before service installation)
- `gh` CLI authenticated (only needed to derive the default clone URL)

## CLI usage

The `plan` executable is on `PATH` at `~/.local/bin/plan` after installation.

### Common operations

```bash
# Create a plan (interactive)
plan new "My Project Plan"

# Create non-interactively (agent/script use)
echo "# My Plan\n\nSteps here." | plan create --title "My Plan" --stdin --json

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

See `claude/skills/plans/references/cli.md` for the full command reference, JSON envelope schema, and exit codes.

## Stable local dashboard URL

```
http://plans.localhost:4173/
```

Each plan has a stable ID-based route:

```
http://plans.localhost:4173/plans/<id>
```

The ID is immutable across title changes, renames, status changes, and archive moves.

## Per-tool invocation

| Tool | Command | Notes |
|---|---|---|
| Claude Code | `/plans` | Delegates to the `plans` skill |
| OpenCode | `/plans` | Delegates to the `plans` skill |
| Copilot CLI | `/plans` | Delegates to the `plans` skill |
| Codex desktop | `$plans` or `/skills` → plans | Preserves native `/plan` mode |
| Codex CLI | `$plans` | Preserves native `/plan` mode |
| Terminal | `plan <command>` | Direct CLI access |

## Fresh-session requirements

After `install/link.sh` completes:

- **Claude Code, OpenCode, Copilot**: instructions load per-session; start a new session to pick up the updated skill and command adapter.
- **Codex desktop**: global guidance loads once at the beginning of a run; start a new desktop task after linking.
- **Codex CLI**: start a new CLI session after linking.

The LaunchAgent starts the dashboard service automatically at login. If the service is not running, `plan serve` starts it.

The generated LaunchAgent is installed at
`~/Library/LaunchAgents/com.plan-manager.serve.plist`. Its resolved home,
worktree, executable, plan root, and runtime `PATH` are machine-specific and are
not committed to dotfiles. Logs remain at:

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

HTML capture uses Pandoc to create canonical GitHub-flavored Markdown. External artifacts remain unchanged and are recorded as the plan's source. Unmanaged Markdown already written inside `~/Developer/plans` is normalized in place with plan-manager metadata. Capturing the same absolute source again updates the existing managed plan only when its converted content changed, preserving its ID and stable dashboard URL. All CLI and dashboard mutations share a bounded writer lock so identical sources converge on one plan, equal-title operations do not overwrite each other, and concurrent revision-guarded updates produce one winner. The dashboard does not crawl tool-specific artifact directories.

## Hosted publishing (optional)

Hosted publishing is opt-in. Local Markdown remains authoritative. It is a planned follow-on capability and is not enabled in the local-only v0.2 release; the remote commands currently fail closed with the documented dependency-unavailable exit code.

```bash
# Add a hosted service
plan remote add default https://<your-hosted-app>.vercel.app

# Authenticate
plan auth login --remote default

# Publish a plan explicitly
plan push <id> --remote default --json

# Check remote status
plan remote status <id> --json
```

See `claude/skills/plans/references/remote.md` for the full publishing workflow.

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

Then reload: `source ~/.zshrc`. Or rerun `install/link.sh` which ensures `~/.local/bin` is on PATH.

### Codex cannot write to `~/Developer/plans`

Check `~/.codex/config.toml` for `sandbox_workspace_write.writable_roots`. If a managed application or organization policy overrides local settings, Codex will request approval — approve it when prompted. `plan doctor` reports this as an effective-access limitation.

### `~/.codex/AGENTS.override.md` shadows policy

A non-empty `AGENTS.override.md` takes precedence over `~/.codex/AGENTS.md`. `plan doctor` reports this conflict. Resolve by removing or merging the override file, then start a new Codex session.

### Stale Codex session

Codex loads global guidance once per run. If plan policy changes are not reflected, start a new desktop task or CLI session.

## Rollback

```bash
# Unload and remove the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.plan-manager.serve.plist
rm ~/Library/LaunchAgents/com.plan-manager.serve.plist

# Remove the CLI symlink (does not touch the application repo)
rm ~/.local/bin/plan

# Restore a backed-up instruction file (example)
mv ~/.codex/AGENTS.md.backup-<timestamp> ~/.codex/AGENTS.md

# Remove a hosted remote without affecting local plans
plan auth logout --remote default
```

Removing the `~/.local/bin/plan` symlink does not delete `~/Developer/sites/plan-manager` or its worktrees. Markdown files under `~/Developer/plans` are user data and are never deleted by rollback or uninstall.

## Installer verification

Run the isolated installer checks without touching live tool configuration or
loading a LaunchAgent:

```bash
~/.dotfiles/install/tests/plan-manager-bootstrap.test.sh
```

The checks cover current bare-worktree resolution, explicit-worktree
validation, missing and conflicting targets, frozen dependency invocation, CLI
link repair, instruction backups, atomic Codex config reconciliation, and
idempotent LaunchAgent rendering under a temporary `HOME`.

To revert the plan-browser output style to the previous behavior, restore `claude/output-styles/plan-browser.md` from git history:

```bash
git -C ~/.dotfiles checkout HEAD~1 -- claude/output-styles/plan-browser.md
```
