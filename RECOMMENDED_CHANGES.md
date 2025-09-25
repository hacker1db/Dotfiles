# Dotfiles Improvement Plan

## 1. Restore or remove `install/nvm.sh`
- Add back the missing `install/nvm.sh` script with the expected nvm bootstrap logic, or stop sourcing it from `install.sh:16`.
- If nvm setup now lives in `install/install_tools.sh`, move the logic there and delete the stale reference so the install script no longer fails.

## 2. Harden `install/install_tools.sh`
- Fix typos such as `brew instal`, `berw install`, and replace deprecated `brew cask install` with `brew install --cask`.
- Remove duplicate or invalid cask entries (`darwio`, second `1password-cli`, etc.) and guard each command so the script keeps going when a tool is unavailable.
- Ensure `nvm` is installed before running `nvm use --lts`; call `nvm install --lts` first or wrap the `use` command in a check.

## 3. Repair macOS defaults script
- Delete the stray `link.s` line at `install/osx.sh:11` so the script doesn’t terminate early and the remaining defaults commands execute as intended.
- Consider grouping the defaults writes into logical sections and echoing each action for easier troubleshooting.

## 4. Make shell startup resilient
- Wrap `source <(kubectl completion zsh)` (and similar blocks) in `command -v` guards so missing commands don’t spam errors in new shells.
- Audit the PATH exports in `zsh/zshrc.symlink` and remove hard-coded usernames or redundant lines to avoid broken paths.
