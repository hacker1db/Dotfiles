# Linux Compatibility

This document tracks Linux installation support and remaining desktop differences. The original audit ran on Ubuntu on 2026-10-16; the devcontainer uses Ubuntu 24.04 on the host’s native architecture.

Detect the platform with `[[ $OSTYPE == darwin* ]]`; the installer scripts are zsh too.

## Devcontainer installation

The devcontainer runs every applicable `install.sh all` step. It uses Homebrew’s standard Linux prefix, changes the login shell through passwordless sudo only when `DOTFILES_NONINTERACTIVE=1`, and skips interactive GitHub login. macOS preferences and default-browser setup are no-ops on Linux.

The Brewfile keeps the existing macOS selection. Linux excludes macOS desktop apps, platform-only formulae, their unused taps, and unavailable legacy packages (`aws-auth`, `dotnet@6`, `python@3.8`, `python@3.9`, and `youtube-dl`). Azure CLI uses its [current cask](https://formulae.brew.sh/cask/azure-cli); TFLint uses the project’s [Go installation](https://github.com/terraform-linters/tflint#installation). Ollama is installed without requesting a system service. `brew-cleanup` preserves these platform rules when capturing installed packages.

Interactive Zsh loads Homebrew from either macOS prefix or `/home/linuxbrew/.linuxbrew`, including its completions, nvm, and mysql-client. pnpm uses `~/.local/share/pnpm` on Linux and `~/Library/pnpm` on macOS, unless `PNPM_HOME` is already set. TPM uses the existing GitHub transport helper, allowing public HTTPS installation without an SSH agent.

Generated Claude and Codex profiles live in dedicated container volumes, separate from host-generated profiles. Git-hook refresh is limited to repositories under the container user’s `~/Developer`. Account sign-in and private integrations still require their normal machine-local setup.

The full toolset, SDKs, caches, and wordlists need substantial disk space. Check available space inside the Podman VM before installation; free space on macOS does not increase the VM’s disk automatically.

## Existing platform support

- `install/lib.zsh`: `load_brew_env` finds Homebrew under `/opt/homebrew`, `/usr/local`, and `/home/linuxbrew`. The SSH preflight falls back to HTTPS when no agent is available.
- `install/tools.zsh`: shell detection uses `getent` on Linux and `dscl` on macOS. The Brewfile selects packages for each platform.
- `install/osx.zsh` skips entirely on Linux.
- `install/theme.zsh`: `sed_inplace` wraps the BSD and GNU `sed -i` differences and uses `[[:space:]]` instead of `\s`.
- `zsh/zshrc.symlink`: `pyenv init` is guarded.
- `zsh/functions/zfetch`: clones over HTTPS.

## Remaining command and desktop gaps

| Location | Problem | Suggested fix |
|---|---|---|
| `bin/e`, `bin/tm` | They use the `#!/bin/sh` shebang but contain bash syntax (`==`, arrays, `select`). On Linux, `/bin/sh` is dash, so they fail. | Change the shebang to `#!/usr/bin/env bash`. |
| `config/tmux/tmux.conf:113-114` | `C-c`/`C-v` use `reattach-to-user-namespace pbcopy/pbpaste`. | tmux-yank is already loaded, so drop the bindings or switch per OS with `if-shell 'uname \| grep -q Darwin'`. |
| `zsh/zshrc.symlink:134-137`, `install/dotnet.zsh` | `DOTNET_ROOT` only checks the macOS brew prefixes before `$HOMEBREW_PREFIX`. | Check `$HOMEBREW_PREFIX/opt/dotnet/libexec` first. |

## macOS-only, should no-op or have a Linux equivalent

| Location | Problem | Suggested fix |
|---|---|---|
| `zsh/aliases.zsh` (49, 83-84, 92-93, 99-102, 112, 120) | `open /Applications/...`, `defaults`, `osascript`, Chrome paths | Wrap them in `if [[ $OSTYPE == darwin* ]]`. |
| `zsh/aliases.zsh:50,68`, `zsh/git.zsh:24-26`, `zsh/functions.zsh:175,186` | `pbcopy`/`pbpaste` | Add `pbcopy`/`pbpaste` shims on Linux that call `wl-copy`/`xclip` (or OSC 52 over SSH). Then the existing aliases keep working. |
| `zsh/aliases.zsh:74` | `stat -f "%z bytes"` is BSD syntax. GNU `stat -f` means filesystem status. | Use `stat -c "%s bytes"` on Linux, or `wc -c <`. |
| `config/nvim/lua/openlink/init.lua:4,44-46` | `open_cmd = "open"` and `osascript` for Spotify | Use `vim.ui.open()`, which works on both OSes. Gate the Spotify branch to macOS. |
| `config/nvim/lua/plugins/extra/obsidian.lua:174` | `jobstart({ "open", url })` | Use `vim.ui.open(url)`. |
| `config/tmux/themes/tmuxlayout.conf:21` | `osascript` "now playing" segment | Show it only on macOS. |
| `config/ghostty/config:9` | `macos-titlebar-style` | Ghostty ignores it on Linux, so no change is needed. |
| `bin/login-shell` | Uses `reattach-to-user-namespace`, but falls back to `exec "$shell" -l` | Works on Linux with this branch's fix. |

## Linux gaps (no equivalent yet)

- **Plan-manager service**: no service is installed on any OS anymore; the hosted site is the dashboard, and `plan serve` runs the local one by hand.
- **1Password SSH agent on Linux**: the socket is `~/.1password/agent.sock`. Each machine owns its `~/.config/1Password/ssh/agent.toml`; Dotfiles does not track it.
- **Clipboard over SSH**: tmux has `set-clipboard on`, so OSC 52 works in Ghostty. Nvim's `unnamedplus` needs a provider (`wl-copy`, `xclip`, or `vim.g.clipboard = "osc52"` when headless).

## Validation

The devcontainer’s startup check verifies Linux, the configured Zsh login shell, Git access to the selected worktree, interactive shell checkout selection, Neovim startup, and the tmux prefix from this repository’s configuration. It uses an isolated tmux socket and removes that server even when a check fails.

The desktop and clipboard operations listed above are outside this startup check.
