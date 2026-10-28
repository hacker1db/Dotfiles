# Fleet integration

[Fleet](https://github.com/nicknisi/fleet) is a terminal dashboard for managing
multiple AI agent sessions in tmux. It watches Claude Code and Codex sessions
through hooks, surfaces hook-less agents (Copilot among them) by spotting them
in the process table, and shows which agents need attention as clickable chips
in the tmux status bar and in the sketchybar agents pill.

## Provenance

- The `fleet` binary is Nick Nisi's [nicknisi/fleet](https://github.com/nicknisi/fleet),
  installed from his [nicknisi/formulae](https://github.com/nicknisi/homebrew-formulae)
  Homebrew tap via the Brewfile.
- The tmux and sketchybar wiring in this repository — `bin/tmux-fleet-chips`,
  `bin/sketchybar-fleet-watch`, the fleet block in `config/tmux/tmux.conf`, and
  the sketchybar agents plugins — is adapted from
  [nicknisi/dotfiles](https://github.com/nicknisi/dotfiles) (MIT).
- Planned follow-ups (multi-machine visibility, T3 Code tracking) are tracked in
  [hacker1db/Dotfiles#72](https://github.com/hacker1db/Dotfiles/issues/72);
  remote-session recognition is proposed upstream in
  [nicknisi/fleet#57](https://github.com/nicknisi/fleet/issues/57).

## Install

The binary comes from the Brewfile (`tap nicknisi/formulae`, `brew fleet`),
along with `fswatch` for the sketchybar push watcher:

```zsh
brew bundle --file=~/.dotfiles/main/install/brewfile
```

Then wire the agent hooks. `install/claude-profiles.zsh` (run via
`~/.dotfiles/main/install.sh claude-profiles`, or as part of
`install.sh all`) does this automatically for every harness:

- **Claude Code** — runs `CLAUDE_CONFIG_DIR=<profile> fleet install` for each
  profile (personal, subscription, foundry) so every config dir gets the
  plugin and hooks fire in new sessions.
- **Codex** — runs `fleet install codex`, which adds fleet hooks to
  `~/.codex/hooks.json` (your own hooks survive).
- **Copilot** — nothing to install: fleet's 5-second process-table discovery
  labels Copilot panes and infers waiting/working/ready from the screen.

Re-run the step after a brew upgrade to re-point the hook paths. The manual
equivalent, for a one-off machine:

```zsh
CLAUDE_CONFIG_DIR=$HOME/.claude-personal fleet install
CLAUDE_CONFIG_DIR=$HOME/.claude-subscription fleet install
CLAUDE_CONFIG_DIR=$HOME/.claude-foundry fleet install

fleet install codex
```

`fleet doctor` verifies tmux version, plugin registration, status dirs, and
hook health.

`fleet install` offers to add its own tmux status row and keybindings — the
installer declines these automatically (stdin is closed, so the prompts
default to no); decline them yourself when running manually. This repo's
`config/tmux/tmux.conf` already carries the one-row wiring below, and its
`# fleet-managed` markers keep `fleet install` from appending duplicates.

## tmux wiring

`config/tmux/tmux.conf` keeps the single status row and mounts the chips in the
theme's `status-right` via `bin/tmux-fleet-chips` (which runs
`fleet status --statusline`). The fleet block sits after the theme sourcing:

| Binding | Action |
| --- | --- |
| `prefix+O` | Fleet dashboard in a popup |
| `prefix+f` | Toggle the persistent fleet sidebar split |
| `prefix+n` | Jump to the next waiting agent pane |
| Left-click a chip | Switch to that agent's pane |
| Right-click a chip | Acknowledge it in place (no switch) |
| Click `✕ clear` | Dismiss every ready agent at once |
| Click `☰` | Open/focus the sidebar |

Only agents whose turn it is for you appear as chips: PERMIT (tool approval),
QUESTION, and DONE/ready. Working and idle sessions stay off the bar — watch
those in the dashboard (`prefix+O`).

After upgrading fleet, run `fleet statusline --inject --force` once to refresh
the click bindings, then `tmux source-file ~/.config/tmux/tmux.conf`.

## sketchybar wiring

`bin/sketchybar-fleet-watch` (spawned by `sketchybarrc`) fswatches the status
dirs fleet's hooks write (`~/.cache/{claude,codex,pi}-status/`) and fires the
`fleet_state_change` trigger that renders the agents pill and attention chip.
Left-click the pill for the fleet popup, right-click for `fleet next`.

## Day-to-day commands

| Command | What it does |
| --- | --- |
| `fleet` | TUI dashboard (also `prefix+O`) |
| `fleet status --json` | Machine-readable snapshot of every agent |
| `fleet list` | Roster of every agent pane |
| `fleet next` | Cycle to the next waiting agent (PERMIT > QUESTION > DONE) |
| `fleet send <session> <prompt>` | Send a prompt; refuses unsafe states unless `--force` |
| `fleet wait <sel> --state ready` | Block until agents reach a state (scripting) |
| `fleet watch --jsonl` | Stream state changes as JSON Lines |
| `fleet capture --pane <sel>` | Read a pane's screen without touching it |
| `fleet doctor` | Health check: tmux, plugin, status dirs, hooks |
| `fleet reconcile` | Clean orphan status files for dead panes |
| `fleet uninstall` / `fleet uninstall codex` | Reverse the hook wiring |

## Troubleshooting

- Chips never appear: `fleet doctor`, then confirm hooks fired by checking
  `~/.cache/claude-status/` for `.status` files while a Claude session runs.
- Stale chips for dead panes: `fleet reconcile --verbose`.
- Chips stopped being clickable after an upgrade:
  `fleet statusline --inject --force`.
- sketchybar pill frozen: confirm `fswatch` is installed and
  `pgrep -f sketchybar-fleet-watch` shows the watcher, then
  `sketchybar --trigger fleet_state_change` to force a render.
