# Herdr integration

[Herdr](https://herdr.dev) is a desktop app for terminals and coding agents.
Its window is built from files in `~/.config/herdr-app`: layouts, a key map,
themes, and JavaScript panels called mods. This repository keeps a layout,
key map, theme, and five mods under `herdr/`.

## Install

`./install.sh tools` runs Herdr's own installer on macOS when neither
`~/Applications/Herdr.app` nor `/Applications/Herdr.app` exists:

```zsh
curl --proto "=https" --tlsv1.2 -fsSL https://releases.herdr.dev/app/install.sh | sh
```

The installer verifies the download's checksum and signature, puts the app in
`~/Applications`, links `~/.local/bin/herdr-app`, and installs herdr-core
(`hc`) if it is missing. The app updates itself after that. Apple Silicon only.

## Linking

Herdr writes its own files into `~/.config/herdr-app` (shipped layouts and
mods, state, type files), so the directory is not linked whole like the
entries under `config/`. `./install.sh link` links each managed file
individually and moves any existing real file aside as `*.backup.<time>`:

| Source | Destination |
|---|---|
| `herdr/keys.json` | `~/.config/herdr-app/keys.json` |
| `herdr/layouts/dotfiles.json` | `~/.config/herdr-app/layouts/dotfiles.json` |
| `herdr/themes/eldritch.json` | `~/.config/herdr-app/themes/eldritch.json` |
| `herdr/mods/<name>/` | `~/.config/herdr-app/mods/<name>` |

If Herdr is running, the link step also switches it to the `dotfiles` layout.
Otherwise switch once with `ctrl-shift-l`, or:

```zsh
herdr-app do layout.switch --name dotfiles
```

`install.sh use` retargets these nested links along with the others.

Herdr does not hot-reload files edited through these links, because file
events report the repository path. Quit and reopen Herdr after editing a
file under `herdr/`. Terminals keep running across the restart.

## Layout

`dotfiles` is a copy of Herdr's `main` layout with these changes:

- The Eldritch theme (the tmux and Ghostty palette) and JetBrains Mono 14.
- The status bar is the `status-bar` mod, moved to the top of the work column
  like the tmux status line.
- The right panel's stack gains `pulls` (the `pull-requests` mod) and `plans`
  (the `plans` mod) beside Files and Changes.

Herdr replaces its shipped layouts on every start. When `main` changes
upstream, compare it with `dotfiles.json` and port what is useful.

## Keys

`keys.json` holds Herdr's macOS defaults, plus three changes:

- `ctrl-a` opens the `prefix` popup, as the tmux prefix does. Ctrl-A no longer
  reaches the shell directly; press `ctrl-a a` to send it.
- `ctrl-a ctrl-a` focuses the next pane, as `bind ^A select-pane -t:.+` does.
- `cmd-shift-n` opens the new-branch dialog, and `cmd-shift-i` the tmux import dialog.
- `cmd-1` to `cmd-9` switch to space 1 to 9, numbered in the status bar, and
  `ctrl-1` to `ctrl-9` select tabs. This swaps Herdr's defaults.
- `ctrl-h`, `ctrl-j`, `ctrl-k`, `ctrl-l` move focus between panes and the
  right-hand panel, like vim-tmux-navigator. In a Neovim pane, or a terminal
  running tmux, the key goes to that program instead, so its own moves keep
  working. The status bar mod handles these keys, so they
  work only in the `dotfiles` layout. Shells no longer get these keys directly
  (backspace, newline, kill-line, and clear-screen), as in tmux with the
  navigator plugin.

Any edit to `keys.json` makes the whole file yours, so later Herdr releases do
not add their new default keys. Compare it with Herdr's `keys.macos.json` after
an upgrade.

After `ctrl-a`:

| Key | Action | tmux equivalent |
|---|---|---|
| `c`, `N` | New tab | `new-window` |
| `\`, `\|` | Split right | `split-window -h` |
| `-` | Split down | `split-window -v` |
| `x` | Close pane | `kill-pane` |
| `&` | Close tab | `kill-window` |
| `h` `j` `k` `l`, arrows | Focus pane | `select-pane` |
| `ctrl-h`, `ctrl-l` | Previous or next tab (repeatable) | `select-window` |
| `M`, `z` | Zoom pane | `resize-pane -Z` |
| `n` | Next agent | `fleet next` |
| `f` | Toggle the Fleet panel | `fleet sidebar` |
| `O` | Fleet dashboard popup | `display-popup fleet` |
| `b` | Toggle sidebar | |
| `I` | Bring tmux into Herdr | |
| `V` | Open a PDF | |
| `o`, `s` | Space picker | sesh |
| `J`, `K` | Next or previous space (repeatable) | |
| `,`, `$` | Rename tab or space | `rename-window`, `rename-session` |
| `p` | Paste | `paste-buffer` |
| `g` | lazygit popup | `display-popup lazygit` |
| `G` | gh dash popup | `display-popup gh dash` |
| `w`, `W` | New branch worktree | |
| `P` | Toggle the pull requests panel | |
| `T` | Toggle the plans panel | |
| `F`, `C` | Toggle the Files or Changes panel | |
| `d` | Minimize the window | detach |
| `1`–`9`, `0` | Select tab 1–10 | `select-window -t` |
| `?` | Show every binding | |

Herdr has no pane resize command, so `H` `J` `K` `L` resizing, `=` tiling and
`y` synchronized panes have no equivalent. `J` and `K` move between spaces
instead.

The `prefix` mod is adapted from Herdr's
[tmux-prefix example](https://github.com/herdrdev/herdr-layout-examples/tree/master/tmux-prefix)
(Apache-2.0). It runs `hc` to send literal keys and to start the lazygit and
gh dash popups.

## Right-hand panel

The panel has a tab strip (the `panel-tabs` mod) for Files, Changes, PRs,
Plans, and Fleet, and ✕ hides it. The status bar chips and the `ctrl-a` keys
open it too. The PRs, Plans, and Fleet panels, and the plan and PR views, take
keyboard focus with `ctrl-h`/`ctrl-l`. In a list, `j`/`k` or the arrows move,
`g`/`G` jump to the ends, Enter opens, and `r` refreshes.

## Status bar

The `status-bar` mod shows, from left to right:

- Spaces numbered for `cmd-1` to `cmd-9`, and the active space's branch.
- Agent counts by status. Click one to jump to the next agent.
- Fleet's agents across tmux and how many wait on you. Click to toggle the
  Fleet panel.
- Open pull requests that request your review. Click to toggle the panel.
- Active plans from the plan CLI. Click to toggle the panel.
- The playing song from `bin/current-song`. Click to play or pause with
  `nowplaying-cli`.
- The time.

It refreshes the song every 5 seconds, plans every 2 minutes, and review
requests every 5 minutes.

## Pull requests panel

`ctrl-a P` or the status bar opens the `pull-requests` mod. It uses the same
sections as gh-dash: needs my review, my pull requests, and other pull requests
that involve you. It runs `gh search prs` with whichever `gh` account is logged
in and refreshes every 2 minutes or on ↻.

Click a pull request to open it as a tab in the current space, named after its
number. The `pr-view` mod shows:

- A header with state, review decision, repository, author, branches, size,
  labels, and links to open it in the browser or reload.
- **Overview**, laid out like the pr-stack-split review dashboard. With the view
  focused, `j`/`k` scroll, `d`/`u` scroll half a screen, and `g`/`G` go to
  the top or bottom:
  - **Headline:** the PR's tier, the reason, and counts of files, lines, failing
    checks, and agent findings.
  - **All findings** from the agent review, sorted trunk → branch → leaf, with
    severity ranking findings within a tier (a critical finding is always
    first). Click a file to open its diff, and **＋ line comment** queues a
    finding as a line comment for the review.
  - **Look at these files first:** the changed files sorted by tier, with each
    file's reason.
  - The description, checks (failing first; click one to open its run), and
    reviewer summaries and comments.
- **Files:** the changed files beside the selected file's diff, from
  `gh pr diff`. Click a diff line to write a comment on it; pending comments
  show 💬 on the line and the file, and ✕ removes one. With the view focused
  (not while typing in an input):
  - `o`/`1` and `f`/`2` switch tabs, `r` reloads, and `?` shows the keys on
    the right of the tab strip.
  - `j`/`k` (or ↓/↑) move a line cursor through the diff, skipping hunk
    headers, and keep it on screen. `d`/`u` move half a page, and `g`/`G` go
    to the first or last line.
  - `J`/`K` or `]`/`[` go to the next or previous file.
  - `c` or Enter opens the comment box on the cursor line, and Escape leaves
    the box without adding anything.
- A review bar: **Approve**, **Request changes**, or **Comment** submits one
  review with the summary and every pending line comment through
  `gh api repos/<owner>/<repo>/pulls/<n>/reviews`. Request changes needs a
  summary; Comment needs a summary or a line comment.

### Changes panel for a pull request

When the active tab holds a PR view, the right panel's **Changes** tab shows
that pull request's changed files (the `pr-changes` mod) instead of the
folder's uncommitted changes. Each file has its tier and line counts. Click a
file, or select it with `j`/`k` and press Enter, to open its diff in the PR
view. On any other tab, **Changes** is Herdr's own folder view again. The
status bar mod finds the PR in the active tab from herdr-core's layout
(`~/.local/state/herdr-core/default/docs.json`) and switches the panel; the PR
view shares its files through Herdr's shared state.

### Trunk, branch, and leaf

Every pull request and changed file gets a tier, as in the pr-stack-split
review dashboard:

- 🌳 **trunk:** a major or cross-cutting change, such as authentication and
  authorization, identity, secrets, CI/CD, IaC, APIM, dependencies, startup,
  and public API or catalog contracts.
- 🌿 **branch:** one service, feature, or endpoint family.
- 🍃 **leaf:** a single function or local detail, tests, or docs.

`herdr/mods/pr-view/tier.js` labels each file from its path (and size), and a
PR takes the highest tier among its files. The PR list shows the tier before
each number. Results are cached by the PR's last update. An agent review can
correct the tier; the header then shows the agent's tier.

### Agent reviews

**Review with agent ▾** in the PR header asks which agent to use. The choices
depend on the repository URL:

| Repository owner | Agents offered |
|---|---|
| Your `github.user`, or any `github.org` value | Codex, Claude personal (`claude-personal`) |
| anything else | GitHub Copilot (`copilot -i`), Claude work (`claude-subscription`), Claude Foundry (`claude-foundry`) |

`install.sh link` asks for `github.user` and writes it to `~/.gitconfig-local`.
To treat an organization's repositories as personal too, add it there:

```zsh
git config -f ~/.gitconfig-local --add github.org <org>
```

The other agents are shown but disabled. The agent starts in a split beside the
PR, in `~/.local/state/herdr-pr-reviews/<owner>/<repo>/<number>`, with the
`pr-review` skill (`/pr-review`, or `$pr-review` for Codex), the tier model,
and an instruction to post nothing to GitHub. It writes `review.json` there:
verdict, tier, summary, and findings with severity, tier, file, and line. The
PR view reads it every 5 seconds and shows the findings in the Overview. You
submit the review yourself from the review bar.

## Plans panel

`ctrl-a T` or the status bar opens the `plans` mod, which reads
`plan list --json` from the plan CLI (see [plan-manager](plan-manager.md)).
Filter by active, completed, archived, or all.

- Click a plan to open it in the `plan-view` mod in a split pane, or in a new
  tab when no pane is focused. The reader shows the title, a status pill, tags,
  and dates above the rendered Markdown body, and reloads when the file
  changes. Its header buttons open the dashboard, open the file in `$EDITOR`,
  and mark the plan completed or reopen it.
- `mermaid` code blocks (```` ```mermaid ````, ```` ``` mermaid ````, `~~~mermaid`,
  indented or not) render as diagrams with `mmdc` from mermaid-cli (in the
  Brewfile), themed by `herdr/mods/plan-view/mermaid.json` in Eldritch
  colors. Each diagram renders once, in a few seconds, and is cached in
  `~/.config/herdr-app/data/mermaid/` by its source, so an edited diagram
  renders again. A diagram that fails shows the error and its source.
- ↗ opens it in the dashboard with `plan open`.
- ✓ marks it completed and ↺ makes it active again, with `plan status`.

## Fleet panel

`ctrl-a f` or the status bar's fleet chip opens the `fleet` mod. It lists
every agent from `fleet list --json`, grouped by tmux session, with agents
that wait on you first. Click one, or select it and press Enter, to switch
your most recently used tmux client (in Ghostty) to that pane and bring Ghostty
to the front. Herdr never runs tmux inside a tab: a second client would shrink
the window to fit both. ▤ opens the Fleet dashboard (`fleet`) in a popup, as does `ctrl-a O`.
Fleet watches agents through tmux, so agents started directly in Herdr are in
Herdr's own agents list instead.

## tmux sync

Herdr owns the running programs, and tmux mirrors them. Each local Herdr
space is a tmux session with the same name, each tab a window, and each
terminal pane a tmux pane that runs `hc attach <terminal>` on the same
herdr-core terminal. Mod panes such as plans and pull requests have no tmux
pane.

`bin/herdr-tmux sync` builds and updates the mirror. The status bar mod runs
it when spaces, tabs, or panes change, and every minute. Closing works both
ways:

- A program that exits, or a pane closed in Herdr, ends the terminal, and its
  `hc attach` pane closes in tmux.
- In a mirror session, `ctrl-a x` and `ctrl-a &` end the terminals with
  `hc kill`, which closes them in Herdr too. `ctrl-a \`, `|`, `-`, `N` and
  `c` start new herdr-core terminals labeled for that space and tab, so they
  appear in Herdr. Outside mirror sessions these keys behave as before.
- Closing a Herdr space ends its tmux session.

Both views share one terminal size, so the larger window shows unused space.
`ctrl+\` detaches `hc attach` without ending the program. A tmux session with
the space's name that is not a mirror makes the mirror `<name> (herdr)`.

### Bringing tmux work into Herdr

`bin/tmux-to-herdr` recreates tmux sessions as Herdr spaces, replaying each
window's split tree from `#{window_layout}`, in the same folders:

- Claude Code panes restart with `claude --continue`, keeping the pane's
  `CLAUDE_CONFIG_DIR` profile. Codex restarts with `codex resume --last`.
  Neovim, lazygit, and yazi start again. Other panes start a shell.
- Without `--replace`, the original tmux session stays and the mirror is named
  `<name> (herdr)`.
- With `--replace`, clients attached to the original switch to the mirror,
  the original session ends, and the mirror takes its name.

From tmux, `ctrl-a T` moves the current session after confirming. From Herdr,
`ctrl-a I` or `cmd-shift-i` opens a dialog with **Copy** and **Move** for each
session.

```zsh
tmux-to-herdr --list
tmux-to-herdr "AppSec items"
tmux-to-herdr --replace work
```

## PDF viewer

The `pdf-view` mod shows a PDF as a Herdr tab: each page rendered at 144 dpi
by `pdftoppm` from poppler (in the Brewfile), drawn on a white page at a
readable width. Rendering starts at the page you are looking at, and pages are
cached in `~/.config/herdr-app/data/pdf/`, keyed by the file's path and
modification time.

- `ctrl-a V` opens a picker of every PDF under the focused pane's repository
  (or folder) with `fd`; type to filter, ↑/↓ and Enter to open.
- `herdr-view report.pdf` opens one from any Herdr terminal.
- With the view focused: `j`/`k` (or arrows, or space) go to the next or
  previous page, `g`/`G` go to the first or last page, `+`/`-` zoom, `0`
  resets the zoom, and `o` opens the file in Preview.

Herdr's own Files panel previews text only and cannot be extended without
copying it, so it does not open PDFs.

## New branch worktree

`ctrl-a w` or `cmd-shift-n` opens the `new-branch` dialog for the repository of
the focused pane. Pick a type (`Tab` cycles them) and type a short description;
`feat` and `add login` become `feat/add-login`. Type a `/` to give the full
branch name.

The dialog runs `bin/wt-new`, which:

1. Runs `wt switch --create <branch> --no-cd`, so Worktrunk's path template and
   approved hooks apply.
2. Copies every gitignored `.env*` file from the current worktree into the new
   one, keeping its relative path and never overwriting. Files inside ignored
   directories such as `node_modules` are skipped.

The new worktree then opens as a Herdr space. The script also works on its own:

```zsh
wt-new feat/add-login
wt-new --json fix/token-refresh release
```

## Access to files in cloud storage

Herdr's shells run under the `herdr-core` server, not the app window. macOS
blocks a background binary from reading cloud storage folders such as
OneDrive under `~/Library/CloudStorage`, and it cannot show the usual prompt.
A `~/.localrc` linked there then fails with `operation not permitted` when
zsh starts. Grant access once:

1. Open System Settings → Privacy & Security → Full Disk Access.
2. Click +, press `cmd-shift-G`, and add
   `~/.local/share/herdr-core/active/Herdr Core.app`. Add
   `~/Applications/Herdr.app` too.
3. Quit Herdr, run `hc server stop`, and open Herdr again so it starts a fresh
   core. `hc server restart` is not enough: the holder process that starts
   shells keeps running and never sees the new permission. Terminals come back
   as fresh shells, so finish any running programs first.

If a test still fails, look for denials:
`sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "select service, client, auth_value from access where client like 'dev.herdr%'"`.
An `auth_value` of 0 for `kTCCServiceFileProviderDomain` means OneDrive access
was denied; `tccutil reset FileProviderDomain dev.herdr.core` (and
`dev.herdr.app`) clears it.

The grant follows the app's signature, so core updates keep it. A managed Mac
may restrict Full Disk Access by policy.

## Checks

```zsh
for m in herdr/mods/*(/); do m=${m:t}
    herdr-app check ~/.config/herdr-app/mods/$m
done
herdr-app status
```

`herdr/mods/pr-view/tier.js` is the tier classifier. Herdr will not load a module from outside a mod's own folder, so `herdr/mods/pull-requests/tier.js` is a copy; keep them identical:

```zsh
cmp herdr/mods/pr-view/tier.js herdr/mods/pull-requests/tier.js
```

`herdr-app status` lists errors from layouts, keys, and mods. Invalid files
also leave `<name>.error` in `~/.config/herdr-app`. `ctrl-alt-shift-escape`
sets the layout and `keys.json` aside and returns to the default `main`
layout if a change breaks the window.
