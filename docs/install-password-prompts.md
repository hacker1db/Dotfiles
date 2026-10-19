# Install password prompts

Steps that ask for the macOS login password run at the end of `./install.sh all`, so the rest of the install does not stop for input.

## How prompts are deferred

- `install.sh all` exports `DOTFILES_DEFER_PROMPTS=1`.
- `install/tools.zsh` installs casks with `SUDO_ASKPASS=/usr/bin/false`. Homebrew passes `SUDO_ASKPASS` through to its own `sudo -A` calls, so a cask that needs a password fails immediately instead of prompting. Its name is written to `${XDG_STATE_HOME:-~/.local/state}/dotfiles/deferred-installs`.
- Mac App Store installs (`mas install`) run through `sudo` in mas 7, so they are not attempted in the main pass; their IDs are recorded in the same file as `mas:<id>`.
- The deferred pass (`./install.sh deferred`, run automatically at the end of `all`) retries those casks with a plain `brew install --cask` and runs the recorded `mas install` commands, where the normal password prompts appear. Anything that still fails stays in the file; rerun `./install.sh deferred`.
- The shell change runs in that same final pass because `chsh` and the `/etc/shells` update ask for a password.

Running `./install.sh tools` on its own installs casks without deferring and ends with the shell change. A cask that fails for another reason, such as a download error, is also retried in the deferred pass.

## Observed prompts

Tools seen asking for a password during an install. Revisit each one to decide whether it stays deferred, gets removed, or needs another approach.

| Tool | Step | Trigger | First seen |
| --- | --- | --- | --- |
| `discord` cask | tools | Upgrade removes the `com.discord.discord.ShipIt` launchctl service | 2026-10-18 |
| `1password` cask | tools | Homebrew still records 1Password 7.9 (`/Applications/1Password 7.app`) while the installed app is a self-updated 1Password 8; the upgrade fails to find the old app, then prompts. Fix once with `brew uninstall --cask --force 1password && brew install --cask --adopt 1password` | 2026-10-18 |
| `gcloud-cli` cask | tools | Upgrade (449.0.0 to 589.0.0) removes the old `Caskroom/gcloud-cli/latest` files | 2026-10-18 |
| `karabiner-elements` cask | tools | Upgrade runs the DriverKit `remove_files.sh` uninstall script as root | 2026-10-18 |
| `krisp` cask | tools | Upgrade runs `pkgutil --forget ai.krisp.krispMac.pkg` as root | 2026-10-18 |
| `microsoft-auto-update` cask | tools | Upgrade removes the `com.microsoft.update.agent` launchctl service and package files as root | 2026-10-18 |
| `microsoft-edge` cask | tools | Upgrade runs `pkgutil --forget com.microsoft.edgemac` as root | 2026-10-18 |
| `microsoft-teams` cask | tools | Upgrade removes package files as root | 2026-10-18 |
| `obs` cask | tools | Upgrade removes old files as root | 2026-10-18 |
| `wireshark-app` cask | tools | Upgrade removes package files as root | 2026-10-18 |
| `zoom` cask | tools | Upgrade removes the `us.zoom.ZoomDaemon` launchctl service as root | 2026-10-18 |
| `gpg-suite-no-mail` cask | tools | Not a password prompt: Homebrew's 2023.3 record points to a missing uninstall script. Fix once with `brew uninstall --cask --force gpg-suite-no-mail` | 2026-10-18 |
| `mas install` (5 App Store apps) | tools | mas 7 runs installs through `sudo` | 2026-10-18 |
| `chsh` / `sudo tee /etc/shells` | deferred | Changing the login shell to Homebrew zsh | Known from `install/tools.zsh` |
