# Install password prompts

Steps that ask for the macOS login password run at the end of `./install.sh all`, so the rest of the install does not stop for input.

## How prompts are deferred

- `install.sh all` exports `DOTFILES_DEFER_PROMPTS=1`.
- `install/install_tools.sh` runs `brew bundle install` with `SUDO_ASKPASS=/usr/bin/false` so casks that need a password fail without stopping for input. Mac App Store IDs are passed through `HOMEBREW_BUNDLE_MAS_SKIP` for this pass because their installs require a password.
- If Bundle fails, a Bundle check excluding casks and App Store apps must pass before the remaining install steps can continue.
- `${XDG_STATE_HOME:-~/.local/state}/dotfiles/deferred-installs` records that Bundle needs a final pass. The `deferred` step reruns `brew bundle install` with normal password prompts, then `brew bundle cleanup` for formulas, casks, taps, and App Store apps. It removes the pending file only after both commands succeed; retry failures with `./install.sh deferred`.
- `shell` runs last because `chsh` and the `/etc/shells` update ask for a password.

Running `./install.sh homebrew` on its own runs Bundle installation and cleanup immediately, with normal password prompts. Failed installation prevents cleanup.

## Observed prompts

Tools seen asking for a password during an install. Revisit each one to decide whether it stays deferred, gets removed, or needs another approach.

| Tool | Step | Trigger | First seen |
| --- | --- | --- | --- |
| `discord` cask | homebrew | Upgrade removes the `com.discord.discord.ShipIt` launchctl service | 2026-10-18 |
| `1password` cask | homebrew | Homebrew still records 1Password 7.9 (`/Applications/1Password 7.app`) while the installed app is a self-updated 1Password 8; the upgrade fails to find the old app, then prompts. Fix once with `brew uninstall --cask --force 1password && brew install --cask --adopt 1password` | 2026-10-18 |
| `gcloud-cli` cask | homebrew | Upgrade (449.0.0 to 589.0.0) removes the old `Caskroom/gcloud-cli/latest` files | 2026-10-18 |
| `karabiner-elements` cask | homebrew | Upgrade runs the DriverKit `remove_files.sh` uninstall script as root | 2026-10-18 |
| `krisp` cask | homebrew | Upgrade runs `pkgutil --forget ai.krisp.krispMac.pkg` as root | 2026-10-18 |
| `microsoft-auto-update` cask | homebrew | Upgrade removes the `com.microsoft.update.agent` launchctl service and package files as root | 2026-10-18 |
| `microsoft-edge` cask | homebrew | Upgrade runs `pkgutil --forget com.microsoft.edgemac` as root | 2026-10-18 |
| `microsoft-teams` cask | homebrew | Upgrade removes package files as root | 2026-10-18 |
| `obs` cask | homebrew | Upgrade removes old files as root | 2026-10-18 |
| `wireshark-app` cask | homebrew | Upgrade removes package files as root | 2026-10-18 |
| `zoom` cask | homebrew | Upgrade removes the `us.zoom.ZoomDaemon` launchctl service as root | 2026-10-18 |
| `gpg-suite-no-mail` cask | homebrew | Not a password prompt: Homebrew's 2023.3 record points to a missing uninstall script. Fix once with `brew uninstall --cask --force gpg-suite-no-mail` | 2026-10-18 |
| `mas install` (5 App Store apps) | homebrew | mas 7 runs installs through `sudo` | 2026-10-18 |
| `chsh` / `sudo tee /etc/shells` | shell | Changing the login shell to Homebrew zsh | Known from `install/shell.sh` |
