# T3 Code from Neovim and tmux

Start, message, steer, stop, and read T3 Code agent threads without opening the desktop app. Both front ends shell out to the `t3` CLI, which talks to the running T3 server, so threads also show up in the desktop and mobile apps.

| Piece | Path |
| --- | --- |
| Neovim module | `config/nvim/lua/t3/init.lua` |
| lazy.nvim spec and keymaps | `config/nvim/lua/plugins/extra/t3.lua` |
| tmux script | `bin/t3-tmux` |
| tmux bindings | `config/tmux/tmux.conf` (T3 block under the fleet popup) |

## Choosing the CLI (`T3_CLI`)

Both front ends run `$T3_CLI`, or `t3` if it is unset. The value may include arguments; a leading `~` is expanded. In Neovim, `opts.cmd` in the lazy spec (a string or a list) overrides the environment variable.

The installed `~/.local/bin/t3` (0.1.9) has `thread list/start/send/show` only. `steer`, `stop`, `send --mode`, `project list`, and `project providers` need a newer build. Until it is installed, point at a source checkout:

```sh
export T3_CLI="node ~/Developer/osc/t3code/feat-hacker1db-all/apps/server/src/bin.ts"
```

A source build only works when the running T3 server is the same version. Otherwise `project …` commands stop with `ServerOwnsDatabaseError` because the CLI would change the database schema. Thread commands go through the running server, not the database.

For tmux, set the variable where the tmux server can see it, for example `tmux set-environment -g T3_CLI "node …/bin.ts"`, or export it before tmux starts.

## Choosing the T3 home (`T3_BASE_DIR`) and start flags (`T3_START_ARGS`)

To drive a T3 server other than the default `~/.t3` (for example a nightly build with its own data directory), set `T3_BASE_DIR`. Both front ends pass it to the CLI as `T3CODE_HOME`. Putting `--base-dir` in `T3_CLI` does not work, because the CLI only accepts that flag after the subcommand. In Neovim, `opts.base_dir` overrides the variable. The last-thread state keys for a non-default home are prefixed with the home's real path, so thread ids from different homes never mix.

`T3_START_ARGS` (Neovim: `opts.start_args`, a string or a list) adds flags to every `t3 thread start`, for example `--provider claudeAgent --model claude-haiku-5-5`.

```sh
export T3_BASE_DIR=~/.t3-hacker1db-nightly
export T3_START_ARGS="--provider claudeAgent --model claude-haiku-5-5"
```

Pair `T3_BASE_DIR` with a CLI from the same build as that server. An older CLI warns that the database migration history diverges.

## Projects and the last thread

The project is the T3 project whose workspace root contains the current file's Git root (Neovim) or the pane's current path (tmux). If the CLI has no `project list` command, or the command fails, the Git root is passed to `t3` as the project. Thread commands accept any path inside a project. When `project list` works and no project matches, you are asked whether to add the Git root with `t3 project add`.

The last thread used in each project is kept in `~/.local/state/t3-cli/last-threads.json`, keyed by the project's real workspace root. Neovim and tmux share it. Starting, picking, showing, or messaging a thread makes it the last thread. Pickers list it first with a ★.

## Neovim

| Command | Keys | Does |
| --- | --- | --- |
| `:T3Start [msg]` | `<leader>Tn` (normal, visual) | Start a thread in this project, then open its transcript |
| `:T3Start!` | `<leader>TN` | Same, in a new worktree; asks for the base ref and branch |
| `:T3Send [msg]` | `<leader>Ts` (normal, visual) | Send to the last thread (queued after a running turn) |
| `:T3Send!` | `<leader>TS` | Pick the thread first |
| `:T3Steer [msg]` | `<leader>Te` (normal, visual) | Steer the last thread's running turn |
| `:T3Steer!` | `<leader>TE` | Pick the thread first |
| `:T3Stop` | `<leader>Tx` | Stop the last thread |
| `:T3Stop!` | `<leader>TX` | Pick the thread first |
| `:T3Show [id]` | `<leader>To` | Open the last thread's transcript (or thread `id`) |
| `:T3Show!` | `<leader>TO` | Pick the thread first |
| `:T3Threads` | `<leader>Tt` | Pick a thread in this project, then show, send, steer, restart, stop, copy its id, or open it in the browser |
| `:T3Threads!` | `<leader>TT` | Pick the project first |
| `:T3Providers [flags]` | `<leader>Tp` | List the project's provider instances; pick one to allow, block, inherit, or allow only that one. With flags, such as `--allow codex --deny claudeAgent`, they go straight to `t3 project providers` |

`<leader>` is `;`. Without a message argument, a compose float opens. Submit with `<C-s>`, `:w`, or `<CR>` in normal mode; cancel with `q` or `<Esc>`. A visual selection is added below the cursor as a fenced block with a `path:line` header, so you type the instruction above it. When no last thread is known, the plain commands open the picker.

The transcript buffer (`t3://<thread id>`, markdown) shows the status, provider, model, worktree, and the latest 20 messages. It refreshes every 3 seconds while it is visible and a turn is preparing, queued, starting, running, or waiting. Keys: `r` refresh, `a` cycle auto-refresh (while running, always, off), `s` send, `S` steer, `x` stop, `q` close. Commands run from the transcript buffer use that thread's project.

Options (`opts` in `plugins/extra/t3.lua`): `cmd`, `base_dir`, `start_args`, `messages` (20), `refresh_ms` (3000, 0 turns it off), `open_on_start` (true), `show_split` (`"botright vsplit"` or `"float"`), `timeout` (120000 ms), `state_file`.

## tmux

| Keys | Does |
| --- | --- |
| `prefix A` | T3 menu: start (`s`), send (`m`), steer (`e`), stop (`x`), watch in a popup (`w`), watch in a new window (`W`), fzf menu (`f`) |
| `prefix C-t` | Start a thread in the pane's directory |

Every action runs `bin/t3-tmux` in a popup at `#{pane_current_path}`. Thread pickers use fzf with a `t3 thread show` preview. Message prompts are one line; leave it empty to write the message in `$EDITOR`. The watch view re-runs `t3 thread show` every 3 seconds (`T3_TMUX_INTERVAL`) with the latest 15 messages (`T3_TMUX_MESSAGES`). In it, `s` sends, `e` steers, `x` stops, `r` refreshes, and `q` quits.

The script also works outside tmux:

```sh
t3-tmux start ~/Developer/project      # or: send | steer | stop | watch | window | menu
t3-tmux watch . <thread-id>
```

`bin/t3m` is the older fzf front end. It reads T3's state database directly and covers projects, models, and the web link. `t3-tmux` uses only the CLI.
