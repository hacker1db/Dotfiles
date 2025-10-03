# Dotfiles Improvement Plan

## 1. Restore or remove `install/nvm.sh`
- Add back the missing `install/nvm.sh` script with the expected nvm bootstrap logic, or stop sourcing it from `install.sh:16`.
- If nvm setup now lives in `install/install_tools.sh`, move the logic there and delete the stale reference so the install script no longer fails.

## 2. Harden `install/install_tools.sh`
- Fix typos such as `brew instal`, `berw install`, and replace deprecated `brew cask install` with `brew install --cask`.
- Remove duplicate or invalid cask entries (`darwio`, second `1password-cli`, etc.) and guard each command so the script keeps going when a tool is unavailable.
- Ensure `nvm` is installed before running `nvm use --lts`; call `nvm install --lts` first or wrap the `use` command in a check.

## 3. Repair macOS defaults script
- Delete the stray `link.s` line at `install/osx.sh:11` so the script doesn't terminate early and the remaining defaults commands execute as intended.
- Consider grouping the defaults writes into logical sections and echoing each action for easier troubleshooting.

## 4. Make shell startup resilient
- Wrap `source <(kubectl completion zsh)` (and similar blocks) in `command -v` guards so missing commands don't spam errors in new shells.
- Audit the PATH exports in `zsh/zshrc.symlink` and remove hard-coded usernames or redundant lines to avoid broken paths.

## 5. Fix slow zsh startup (critical performance issues)
**Major Performance Problems:**
- **Line 88**: `source <(kubectl completion zsh)` runs UNCONDITIONALLY (even though line 17-19 already does this conditionally!)
  - This is a DUPLICATE that generates completion code every shell start
  - Should be removed entirely (already handled by guarded version at line 17-19)
- **Line 11 & 15**: `compinit` called TWICE (massive slowdown on each startup)
- **Lines 40 & 116-119**: All .zsh files sourced TWICE (complete duplication of work)
- **Line 88-90**: kubectl completion runs without checking if kubectl exists
- **Lines 68-70, 121-124, 131**: Multiple `eval` calls (fnm, zoxide, starship) - each spawns subprocess
- **Line 14**: `compinit` called again without check flag (should use `-C` to skip check on subsequent runs)

**Quick fixes (will dramatically improve startup):**
1. Remove line 88 (duplicate kubectl completion)
2. Remove one of the duplicate `compinit` calls (line 15)
3. Remove duplicate .zsh sourcing (either lines 40 OR 116-119, not both)
4. Add `-C` flag to second compinit call to skip security check
5. Consider lazy-loading completions only when needed

**Estimated improvement:** 50-80% faster startup (from ~2-3s to ~500ms)

## 6. Snacks.nvim (selective integration strategy)
- Status: Introduced `snacks.nvim` with a focused set of non-invasive quality-of-life modules.
- Adopted Now:
  - **snacks.notifier** – Replaces `nvim-notify` (cleaner UI, unified style)
  - **snacks.indent** – Replaces `indent-blankline.nvim` (lighter config)
  - **snacks.scroll** – Smooth scrolling
  - **snacks.words** – LSP reference / word highlight navigation
  - **snacks.bufdelete** – Safe buffer closing without layout churn
  - **snacks.zen** – Distraction-free coding mode (replaces twilight use-cases gradually)
  - **snacks.terminal** – Integrated floating / split terminal ergonomics
  - **snacks.lazygit** – Native LazyGit integration with colorscheme sync
- Deferred / Not Enabled (by design):
  - **snacks.picker** – Keeping Telescope for now (better git/LSP ecosystem). Only enable if it demonstrably improves performance or ergonomics.
  - **snacks.explorer** – Keeping `nvim-tree` (stable + muscle memory). Explorer will be reconsidered only if it adds clear workflow advantages.
- Potential Future Enhancements (evaluate later):
  - **snacks.dashboard** – Could replace any future startup screen need
  - **snacks.quickfile** – Rapid scratch / transient file workflow (if enabled in upstream)
  - **snacks.image** – Inline / floating image preview support (depends on workflow need)
  - **snacks.gitbrowse / gitbrows** – If/when upstream provides quick repo file/GitHub navigation
  - **snacks.statuscolumn** – Optional UI polish (low priority)
- Rationale: Minimize churn while consolidating lightweight UX layers under one maintained plugin. Preserve existing Telescope + nvim-tree flows until a net advantage is proven.
- Next Evaluation Triggers:
  - Benchmark picker startup vs Telescope on large repos
  - Need for richer explorer features (git decorators performance, preview panels)
  - Desire for startup dashboard or image preview workflows.
- Action Items (if adopting more later): Add module enable flags in `snacks.lua`, migrate keymaps behind alternate leader prefixes, then phase out redundant plugins after trial period.
