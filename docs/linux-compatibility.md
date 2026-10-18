# Linux Compatibility

Audit of macOS-only behavior, run on Ubuntu (Linux 7.0, Linuxbrew at `/home/linuxbrew/.linuxbrew`, `/bin/sh` → dash) on 2026-10-16. The goal for a follow-up PR is for every item to work on macOS and Linux, or to be skipped cleanly on Linux.

Detect the platform with `[[ "$(uname -s)" == Darwin ]]` in installer scripts and `[[ $OSTYPE == darwin* ]]` in zsh, which matches the existing code.

## Already handled on `feature/cleanUpNvimfiles`

- `install/lib/env.sh`: `load_brew_env` finds Homebrew under `/opt/homebrew`, `/usr/local`, and `/home/linuxbrew`. The SSH preflight falls back to HTTPS when no agent is available.
- `install/install_tools.sh`: casks, `mas`, and `reattach-to-user-namespace` only run on Darwin.
- `install/osx.sh`, `install/nvimtmux.sh`, and the plan-manager LaunchAgent skip on Linux.
- `install/shell.sh`: reads the login shell from `getent` on Linux and `dscl` on macOS.
- `install/theme.sh`: `sed_inplace` wraps the BSD and GNU `sed -i` differences and uses `[[:space:]]` instead of `\s`.
- `zsh/zshrc.symlink`: `pyenv init` is guarded.
- `zsh/functions/zfetch`: clones over HTTPS.

## Broken on Linux (fix first)

| Location | Problem | Suggested fix |
|---|---|---|
| `zsh/git.zsh:110` | Always exports `SSH_AUTH_SOCK` to the 1Password socket under `~/Library`. On Linux this socket path doesn't exist, so every shell loses its real or forwarded agent. Confirmed: `zsh -i` prints the bogus path. | Export it only when the socket exists (`[[ -S $sock ]]`), or use `~/.1password/agent.sock` on Linux. |
| `ssh/config:11` | `IdentityAgent` for `192.168.1.157` points to the macOS socket. | Use `Match exec` on the OS, or move it to a per-host `config-accounts` include. |
| `git/gitconfig.symlink:151` | `credential.helper = osxkeychain`. Linux git errors with `'credential-osxkeychain' is not a git command`. | Move it to `~/.gitconfig-local`, or use `[includeIf]` with a macOS-only file. Linux can use `!gh auth git-credential` or `libsecret`. |
| `git/profiles/hacker1db/gitconfig:7` | `gpg.ssh.program` is set to `/Applications/1Password.app/.../op-ssh-sign`, so commit signing fails on Linux. | On Linux, use `/opt/1Password/op-ssh-sign` and pick the path per OS. |
| `git/profiles/hacker1db/gitconfig:20` | Hardcodes `/opt/homebrew/bin/gh`. | Use `!gh auth git-credential`, as line 17 already does. |
| `bin/git-agent-key:16`, `bin/git-agent-ssh:23` | Hardcode the macOS 1Password socket. | Share one socket-resolver helper that also handles the Linux path. |
| `bin/e`, `bin/tm` | They use the `#!/bin/sh` shebang but contain bash syntax (`==`, arrays, `select`). On Linux, `/bin/sh` is dash, so they fail. | Change the shebang to `#!/usr/bin/env bash`. |
| `config/tmux/tmux.conf:113-114` | `C-c`/`C-v` use `reattach-to-user-namespace pbcopy/pbpaste`. | tmux-yank is already loaded, so drop the bindings or switch per OS with `if-shell 'uname \| grep -q Darwin'`. |
| `zsh/zshrc.symlink:116` | Always prepends `/opt/homebrew/bin`. This is harmless on Linux but it puts a nonexistent directory first in PATH. | Guard it with `[[ -d /opt/homebrew/bin ]]`. `zsh/brew.zsh` already does the shellenv part. |
| `zsh/brew.zsh` | Only loads `/opt/homebrew`. Linuxbrew shellenv, nvm, and mysql-client never load in an interactive zsh. | Use the same candidate loop as `load_brew_env`. Base `nvm`/`mysql-client` on `$HOMEBREW_PREFIX`. |
| `zsh/zshrc.symlink:134-137`, `install/dotnet-tools.sh:13-14` | `DOTNET_ROOT` only checks the macOS brew prefixes. | Check `$HOMEBREW_PREFIX/opt/dotnet/libexec` first. |
| `PNPM_HOME` default (`zsh/zshrc.symlink:111`, `zsh/functions.zsh:261`, `install/node-tools.sh:10`, `install/install_tools.sh:207`) | `~/Library/pnpm` is used on every OS. pnpm uses `~/.local/share/pnpm` on Linux. | Choose the path per OS in one place. Keep the existing `${PNPM_HOME:-...}` override. |
| `install/tests/plan-manager-bootstrap.test.sh:230` | Calls `plutil`, which only exists on macOS. Confirmed: this test fails on Linux. | Skip the LaunchAgent assertions when the OS isn't Darwin. |

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
| `install/extras.sh:9-11` | Rancher Desktop path under `~/Library/Application Support` | Already guarded by `[ -d ]`, so no change is needed. |
| `bin/azure-openai-token:8-12` | Only checks the macOS `az` paths | Fall back to `command -v az` first. |
| `bin/login-shell` | Uses `reattach-to-user-namespace`, but falls back to `exec "$shell" -l` | Works on Linux with this branch's fix. |
| `config/opencode/package-lock.json` | Only pins the darwin `msgpackr-extract` optional dependencies | Regenerate it on Linux or let npm pick the platform optional dependency. Verify `opencode` plugins load. |
| `install/brewfile` | Contains `cask`/`mas` entries | `brew bundle` on Linux skips casks with warnings. Consider `if OS.mac?` blocks. |

## Linux gaps (no equivalent yet)

- **Plan-manager service**: macOS uses launchd. Linux has no service. `~/.config/systemd/user/` exists on this host (lima only), so a systemd user unit template beside `launchd/` would match.
- **1Password SSH agent on Linux**: the socket is `~/.1password/agent.sock`. `config/1Password/ssh/agent.toml` is cross-platform.
- **Clipboard over SSH**: tmux has `set-clipboard on`, so OSC 52 works in Ghostty. Nvim's `unnamedplus` needs a provider (`wl-copy`, `xclip`, or `vim.g.clipboard = "osc52"` when headless).

## Verified on Linux

- `zsh -n` passes for every file under `zsh/`.
- `zsh -i -c exit` starts without errors.
- `install/tests/claude-profiles.test.py`, `claude-session.test.sh`, and `plan-manager-harness-contracts.test.mjs` pass.
- `plan-manager-bootstrap.test.sh` fails at `plutil` (see the table above).
