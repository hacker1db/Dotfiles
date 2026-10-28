# SketchyBar

The bar config at `config/sketchybar/` is ported from
[nicknisi/dotfiles](https://github.com/nicknisi/dotfiles) (MIT) and themed through
`install/theme.zsh`: `themes/current.sh` is a symlink to the active `themes/<name>.sh`
palette, managed by `theme apply <name>`.

## Setup

```zsh
brew bundle --file=~/.dotfiles/main/install/brewfile   # sketchybar, nowplaying-cli
brew services start sketchybar
```

The bar draws on the macOS main display (`display=main`). Hide the menu bar
(System Settings → Control Center → automatically hide) for the intended look.

## Upstream assumptions and how this port degrades

- **AeroSpace/OmniWM**: upstream exits without a tiling WM. Here the workspace
  pills, binding-mode badge, and WM watchdog are skipped and the center title
  follows the frontmost app. With AeroSpace installed, the upstream behavior
  returns on reload.
- **fleet**: his agent-fleet watcher is not ported. The agents pill counts
  claude/codex panes found in tmux and hides when there are none; the attention
  chip needs fleet's hook status files and stays hidden.
- **`sessions report`** (spend pill) hides itself when the tool is absent.
- **GitHub pill** uses `gh`; **music pill** uses `nowplaying-cli` via
  `bin/current-song` and `bin/album-art` (shared with the tmux bar's now-playing
  segment).
- The Claude usage pill reads `~/.cache/claude-usage.json`, which
  `claude/statusline-command.sh` tees from the statusline's `rate_limits` input.

## tmux bar layout

The tmux status bar layout lives in `config/tmux/themes/<name>-layout.conf`
(nicknisi's April 2026 powerline bar, rendered static per theme palette):
session segment, dim windows with nerd-font icons, now-playing and git-status
segments. `tmux.conf` sources `themes/current-layout.conf` quietly after
`tmuxlayout.conf`; `theme apply` links it for themes that ship a layout and
removes it otherwise, which restores the default `tmuxlayout.conf` bar.
