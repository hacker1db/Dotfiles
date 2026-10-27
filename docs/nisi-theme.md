# Nisi Theme

A port of the visual theme from [nicknisi/dotfiles](https://github.com/nicknisi/dotfiles) (MIT),
using his Tokyo Night palette (`themes/tokyo-night/colors.toml`, his documented default) rendered
through his own template definitions. Colors and appearance only — no keybindings or behavior
were copied, and existing configs keep working with the current `eldritch` theme until `nisi`
is applied.

## What is included

| App | File(s) | Notes |
|-----|---------|-------|
| tmux | `config/tmux/themes/nisi.conf` | Palette only; the existing status bar layout (`tmuxlayout.conf`) renders in his colors |
| Ghostty | `config/ghostty/themes/Nisi` | Full palette, cursor, and selection colors |
| Starship | `[palettes.nisi]` in `config/starship/starship.toml` | Selected by `theme apply` |
| Neovim | `config/nvim/lua/plugins/ui/nisi.lua` + `config/theme/nisi/nvim-aether.json` | His `aether.nvim` colorscheme fed the same rendered palette; active only when the theme is `nisi` (`core/theme.lua` reads `~/.config/theme/current`) |
| SketchyBar | `config/sketchybar/` | His full "Phosphor" bar, ported (see below) |
| Claude Code status line | `claude/statusline-command.sh` | His statusline script, path-compatible with the existing `settings.base.json` wiring |
| Claude Code theme | `claude/themes/nisi.json` | Linked into each profile by `install/claude-profiles.zsh`; select with `/config` → theme → `custom:nisi` |

## Activating

```zsh
~/.dotfiles/main/install/theme.zsh apply nisi
```

This records the theme, points `config/tmux/themes/current.conf` and
`config/sketchybar/themes/current.sh` at the nisi files, sets `theme = Nisi` in the Ghostty
config, and sets `palette = "nisi"` in Starship. Restart Neovim afterwards; it reads
`~/.config/theme/current` at startup. `theme.zsh apply eldritch` switches everything back
(SketchyBar falls back to its built-in Ayu/Phosphor baseline, which has no eldritch variant).

## SketchyBar

New config at `config/sketchybar/` (symlinked to `~/.config/sketchybar` by the linker).
Install and start it:

```zsh
brew bundle --file=~/.dotfiles/main/install/brewfile   # sketchybar, nowplaying-cli
brew services start sketchybar
```

Hide the macOS menu bar (System Settings → Control Center → automatically hide) for the
intended look. Upstream assumptions and how this port degrades without them:

- **AeroSpace/OmniWM**: upstream exits without a tiling WM. Here the workspace pills,
  binding-mode badge, and WM watchdog are skipped and the center title follows the
  frontmost app instead. If AeroSpace is installed later, the full upstream behavior
  returns on reload.
- **fleet**: his agent-fleet watcher is not ported. The agents pill still counts
  claude/codex panes found in tmux and hides when there are none; the attention chip
  needs fleet's hook status files and stays hidden.
- **`sessions report`** (spend pill) hides itself when the tool is absent.
- **GitHub pill** uses `gh` (already installed); **music pill** uses `nowplaying-cli`
  via `bin/current-song` and `bin/album-art`.
- Labels use the already-installed Monaspace and Symbols Nerd Font casks.

## Claude Code

`claude/statusline-command.sh` is replaced by his statusline (branch, model and agent on
the left; lines changed, cost, context bar, rate-limit windows, and output style on the
right, spread to the pane width). The `statusLine` block in settings is unchanged — it
already points at this script. Opt-out env vars: `CLAUDE_STATUSLINE_TOKENS=0`,
`CLAUDE_STATUSLINE_USAGE=0`. The script also tees rate limits to
`~/.cache/claude-usage.json`, which feeds the SketchyBar usage pill.

The `custom:nisi` Claude theme is not auto-selected; pick it per profile with `/config`.
