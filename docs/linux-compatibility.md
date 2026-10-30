# Linux Compatibility

Audit of macOS-only behavior, run on Ubuntu (Linux 7.0, Linuxbrew at `/home/linuxbrew/.linuxbrew`, `/bin/sh` → dash) on 2026-10-16. The goal for a follow-up PR is for every item to work on macOS and Linux, or to be skipped cleanly on Linux.

Detect the platform with `[[ $OSTYPE == darwin* ]]`; the installer scripts are zsh too.

## Already handled on `feature/cleanUpNvimfiles`

- `install/lib.zsh`: `load_brew_env` finds Homebrew under `/opt/homebrew`, `/usr/local`, and `/home/linuxbrew`. The SSH preflight falls back to HTTPS when no agent is available.
- `install/tools.zsh`: casks and `mas` only run on Darwin, and the shell change reads the login shell from `getent` on Linux and `dscl` on macOS.
- `install/osx.zsh` skips entirely on Linux.
- `install/theme.zsh`: `sed_inplace` wraps the BSD and GNU `sed -i` differences and uses `[[:space:]]` instead of `\s`.
- `zsh/zshrc.symlink`: `pyenv init` is guarded.
- `zsh/functions/zfetch`: clones over HTTPS.

## Broken on Linux (fix first)

| Location | Problem | Suggested fix |
|---|---|---|
| `git/gitconfig.symlink:151` | `credential.helper = osxkeychain`. Linux git errors with `'credential-osxkeychain' is not a git command`. | Move it to `~/.gitconfig-local`, or use `[includeIf]` with a macOS-only file. Linux can use `!gh auth git-credential` or `libsecret`. |
| `bin/e`, `bin/tm` | They use the `#!/bin/sh` shebang but contain bash syntax (`==`, arrays, `select`). On Linux, `/bin/sh` is dash, so they fail. | Change the shebang to `#!/usr/bin/env bash`. |
| `config/tmux/tmux.conf:113-114` | `C-c`/`C-v` use `reattach-to-user-namespace pbcopy/pbpaste`. | tmux-yank is already loaded, so drop the bindings or switch per OS with `if-shell 'uname \| grep -q Darwin'`. |
| `zsh/zshrc.symlink:116` | Always prepends `/opt/homebrew/bin`. This is harmless on Linux but it puts a nonexistent directory first in PATH. | Guard it with `[[ -d /opt/homebrew/bin ]]`. `zsh/brew.zsh` already does the shellenv part. |
| `zsh/brew.zsh` | Only loads `/opt/homebrew`. Linuxbrew shellenv, nvm, and mysql-client never load in an interactive zsh. | Use the same candidate loop as `load_brew_env`. Base `nvm`/`mysql-client` on `$HOMEBREW_PREFIX`. |
| `zsh/zshrc.symlink:134-137`, `install/dotnet.zsh` | `DOTNET_ROOT` only checks the macOS brew prefixes before `$HOMEBREW_PREFIX`. | Check `$HOMEBREW_PREFIX/opt/dotnet/libexec` first. |
| `PNPM_HOME` default (`zsh/zshrc.symlink:111`, `zsh/functions.zsh:261`, `install/node.zsh`) | `~/Library/pnpm` is used on every OS. pnpm uses `~/.local/share/pnpm` on Linux. | Choose the path per OS in one place. Keep the existing `${PNPM_HOME:-...}` override. |

## macOS-only, should no-op or have a Linux equivalent

| Location | Problem | Suggested fix |
|---|---|---|
| `zsh/aliases.zsh` (49, 83-84, 92-93, 99-102, 112, 120) | `open /Applications/...`, `defaults`, `osascript`, Chrome paths | Wrap them in `if [[ $OSTYPE == darwin* ]]`. |
| `zsh/aliases.zsh:50,68`, `zsh/git.zsh:24-26`, `zsh/functions.zsh:175,186` | `pbcopy`/`pbpaste` | Add `pbcopy`/`pbpaste` shims on Linux that call `wl-copy`/`xclip` (or OSC 52 over SSH). Then the existing aliases keep working. |
| `zsh/aliases.zsh:74` | `stat -f "%z bytes"` is BSD syntax. GNU `stat -f` means filesystem status. | Use `stat -c "%s bytes"` on Linux, or `wc -c <`. |
| `zsh/functions.zsh:224` | `brew bundle dump --mas --cask` | Drop `--mas --cask` on Linux. |
| `zsh/zshenv.symlink:14` | `/usr/local/share/zsh/site-functions` in `fpath` | Add `$HOMEBREW_PREFIX/share/zsh/site-functions`. Missing directories are harmless. |
| `config/nvim/lua/openlink/init.lua:4,44-46` | `open_cmd = "open"` and `osascript` for Spotify | Use `vim.ui.open()`, which works on both OSes. Gate the Spotify branch to macOS. |
| `config/nvim/lua/plugins/extra/obsidian.lua:174` | `jobstart({ "open", url })` | Use `vim.ui.open(url)`. |
| `config/tmux/themes/tmuxlayout.conf:21` | `osascript` "now playing" segment | Show it only on macOS. |
| `config/ghostty/config:9` | `macos-titlebar-style` | Ghostty ignores it on Linux, so no change is needed. |
| `bin/login-shell` | Uses `reattach-to-user-namespace`, but falls back to `exec "$shell" -l` | Works on Linux with this branch's fix. |
| `install/brewfile` | Contains `cask`/`mas` entries | `brew bundle` on Linux skips casks with warnings. Consider `if OS.mac?` blocks. |

## Linux gaps (no equivalent yet)

- **Plan-manager service**: no service is installed on any OS anymore; the hosted site is the dashboard, and `plan serve` runs the local one by hand.
- **1Password SSH agent on Linux**: the socket is `~/.1password/agent.sock`. `config/1Password/ssh/agent.toml` is cross-platform.
- **Clipboard over SSH**: tmux has `set-clipboard on`, so OSC 52 works in Ghostty. Nvim's `unnamedplus` needs a provider (`wl-copy`, `xclip`, or `vim.g.clipboard = "osc52"` when headless).

## Verified on Linux

- `zsh -n` passes for every file under `zsh/`.
- `zsh -i -c exit` starts without errors.
