# Install password prompts

Steps that ask for the macOS login password run at the end of `./install.sh all`, so the rest of the install does not stop for input.

## How prompts are deferred

- `install.sh all` exports `DOTFILES_DEFER_PROMPTS=1`.
- `install/install_tools.sh` installs casks with `SUDO_ASKPASS=/usr/bin/false`. Homebrew passes `SUDO_ASKPASS` through to its own `sudo -A` calls, so a cask that needs a password fails immediately instead of prompting. Its name is written to `${XDG_STATE_HOME:-~/.local/state}/dotfiles/deferred-casks`.
- The `deferred` step (`install/deferred.sh`) retries those casks with a plain `brew install --cask`, where the normal password prompt appears. Casks that still fail stay in the file; rerun `./install.sh deferred`.
- `shell` runs last because `chsh` and the `/etc/shells` update ask for a password.

Running `./install.sh homebrew` on its own installs casks without deferring. A cask that fails for another reason, such as a download error, is also retried in the `deferred` step.

## Observed prompts

Tools seen asking for a password during an install. Revisit each one to decide whether it stays deferred, gets removed, or needs another approach.

| Tool | Step | Trigger | First seen |
| --- | --- | --- | --- |
| `discord` cask | homebrew | Upgrade removes the `com.discord.discord.ShipIt` launchctl service | 2026-10-18 |
| `chsh` / `sudo tee /etc/shells` | shell | Changing the login shell to Homebrew zsh | Known from `install/shell.sh` |
