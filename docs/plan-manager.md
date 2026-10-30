# Plan Manager

A tool-neutral local plan library backed by `~/notes/SecondBrain/4.Resources/plans`, published to the hosted site, and accessible from Claude Code, Copilot, and Codex through the shared `plans` skill. `plan serve` still runs the local dashboard at `http://plans.localhost:4173/` by hand; no service is installed.

## Application repository

The plan-manager application — CLI, local server, dashboard, hosted Next.js app, migrations, and tests — lives in a dedicated Git repository separate from dotfiles:

- Default location: `~/Developer/plan-manager`
- Override: set `PLAN_MANAGER_REPO_DIR` before running `./install.sh link`

Dotfiles owns the clone-and-install step, the global instructions, and the command adapters. The shared `plans` skill, including its contract and evals, lives in the skills repository. Application code is never copied into dotfiles.

### Repository layouts

`install/link.zsh` supports two checkout layouts at the target root:

| Layout | Description | Resolved worktree |
| --- | --- | --- |
| Normal clone | Standard `git clone` | `~/Developer/plan-manager` |
| Bare + linked worktree | `.bare` dir + `main/` linked worktree | `~/Developer/plan-manager/main` |

Fresh clones use a normal clone. Existing bare repositories with a `main/` worktree are supported.

The following overrides are supported:

- `PLAN_MANAGER_REPO_DIR`: repository container or normal-clone path
- `PLAN_MANAGER_REPO_URL`: the clone URL used when the checkout is missing
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
PLAN_MANAGER_REPO_URL=git@github.com:<your-user>/plan-manager.git ./install.sh link
```

Existing checkouts are never reset, cleaned, stashed, or branch-switched. Dirty
worktrees are preserved and reported; only a clean checkout with an upstream is
fast-forwarded.

## Bootstrap and installation

```bash
# On any machine after cloning dotfiles
cd ~/.dotfiles/main
./install.sh link
```

The link step:

1. Resolves or clones the plan-manager repository (an existing checkout under `~/Developer/<name>` or `~/Developer/*/<name>` with a matching `origin` is used first; otherwise a fork's own plan-manager, falling back to `hacker1db/plan-manager`).
2. Fast-forwards a clean checkout, then runs `GOBIN=~/.local/bin GOWORK=off go install -mod=readonly ./cmd/plan` from its `cli` module. Go enforces the toolchain requirement in `cli/go.mod`; a failed build leaves the previous command in place.
3. Links the global instructions and command adapters. Install the `plans` skill separately through skillctl.
4. Checks that `~/.codex/config.toml` lists the plan library under `sandbox_workspace_write.writable_roots`: it creates the file or appends the section when missing, and otherwise reports the one line to add by hand.

A plan-manager failure is reported after other dotfiles links have been attempted and makes the linker exit nonzero.

### Prerequisites

- Go satisfying `cli/go.mod` (Go may download the required toolchain)
- `gh` CLI authenticated (only needed to derive the default clone URL)
- Pandoc, for `plan capture` of HTML artifacts and the hand-run local dashboard

## CLI usage

The `plan` executable is installed at `~/.local/bin/plan`. Dotfiles Zsh startup deduplicates `PATH` and puts that directory first after tool initialization, then loads completions from the selected command. pnpm global commands remain available.

The binary does not carry environment variables. For terminal invocations, set the canonical root in `~/.localrc` and reload the shell:

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

## Per-tool invocation

| Tool | Command | Notes |
| --- | --- | --- |
| Claude Code | `/plans` | Delegates to the `plans` skill |
| Copilot CLI | `/plans` | Delegates to the `plans` skill |
| Codex desktop | `$plans` or `/skills` → plans | Preserves native `/plan` mode |
| Codex CLI | `$plans` | Preserves native `/plan` mode |
| Terminal | `plan <command>` | Direct CLI access |

## Fresh-session requirements

After `./install.sh link` completes:

- **Claude Code, Copilot**: start a new session to pick up updated instructions and command adapters; ensure the shared skill is installed separately.
- **Codex desktop**: global guidance loads once at the beginning of a run; start a new desktop task after linking.
- **Codex CLI**: start a new CLI session after linking.

No service is installed. The hosted site is always available; run `plan serve` when the local dashboard is needed. A machine that still has the old LaunchAgent loaded can remove it with `launchctl bootout gui/$(id -u)/com.plan-manager.serve` and `rm ~/Library/LaunchAgents/com.plan-manager.serve.plist`.

## Migration from legacy plan locations

Existing Markdown plans under `~/.claude/plans/` are not migrated automatically. Import them explicitly to preserve originals:

```bash
# Import one plan
plan import ~/.claude/plans/my-plan.md

# Import all plans
for f in ~/.claude/plans/*.md; do plan import "$f"; done
```

The source file is never modified or deleted. The imported copy appears in the dashboard at its stable ID-based URL.

Standalone Markdown or HTML artifacts created by Claude Code, Codex, or Copilot can be registered explicitly:

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

- Service not started: `plan serve` to start it (nothing starts it automatically).
- Port 4173 occupied: `plan doctor` reports the owning process. Resolve the collision, then `plan serve`.

### `plan: command not found`

`~/.local/bin` is not on `PATH`. Add it in `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload: `source ~/.zshrc; rehash`, or open a fresh terminal. Rerun `./install.sh link` only if the installed binary needs repair; its environment changes do not modify the parent shell.

### Wrong implementation or stale completions

```sh
type -a plan
whence -w plan
go version -m "$HOME/.local/bin/plan"
plan completion zsh
```

Expect `~/.local/bin/plan` first and package identity `github.com/hacker1db/plan-manager/cli/cmd/plan` with module `github.com/hacker1db/plan-manager/cli`. Versions alone do not distinguish Go and TypeScript. Reload Zsh and run `rehash` after updating dotfiles. Inspect user aliases/functions if a different command is still selected. The installer requires the checkout to contain `cli/go.mod`; it never silently changes branches or falls back to TypeScript.

### Codex cannot write to `~/notes/SecondBrain/4.Resources/plans`

Check `~/.codex/config.toml` for `sandbox_workspace_write.writable_roots`. If a managed application or organization policy overrides local settings, Codex will request approval — approve it when prompted. `plan doctor` reports this as an effective-access limitation.

### `~/.codex/AGENTS.override.md` shadows policy

A non-empty `AGENTS.override.md` takes precedence over `~/.codex/AGENTS.md`. `plan doctor` reports this conflict. Resolve by removing or merging the override file, then start a new Codex session.

### Stale Codex session

Codex loads global guidance once per run. If plan policy changes are not reflected, start a new desktop task or CLI session.

## Rollback

Reinstall an earlier version by checking out the wanted commit in `~/Developer/plan-manager` and rerunning `./install.sh link`, or remove the binary entirely:

```bash
# Remove the installed CLI (does not touch the application repo)
rm ~/.local/bin/plan

# Restore a backed-up instruction file (example)
mv ~/.codex/AGENTS.md.backup.<timestamp> ~/.codex/AGENTS.md

# Clear hosted authentication without deleting local plans
plan auth logout
```

Removing `~/.local/bin/plan` does not delete `~/Developer/plan-manager` or its worktrees. Markdown files under `~/notes/SecondBrain/4.Resources/plans` are user data and are never deleted by rollback or uninstall.

To undo an output-style change, inspect its Git history and restore the intended revision of `claude/output-styles/plan-browser.md`; do not assume the previous commit contains the desired version.
