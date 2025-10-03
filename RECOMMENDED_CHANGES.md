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

## 6. Snacks.nvim (UI consolidation) ✅

- Status: Fully consolidated multiple UI plugins into `snacks.nvim`.
- Now Enabled: notifier, indent, scroll, words, bufdelete, zen, terminal, lazygit, picker, explorer, dashboard, quickfile, image, gitbrowse, statuscolumn.
- Replaced / Removed:
  - `alpha-nvim` (startup screen) → snacks dashboard
  - `nvim-tree` (file explorer) → snacks explorer
  - `nvim-notify` (notifications) → snacks notifier
  - `indent-blankline.nvim` (indent guides) → snacks indent
  - `twilight.nvim` (focus/zen) → snacks zen
- Telescope: Still used for git-specific pickers and extensions; snacks picker handles files/grep/buffers/help. May migrate git flows later if parity improves.
- Key UX Changes:
  - Fixed left explorer (width 30) with auto-close on file open
  - Dashboard key actions (n/e/f/s/q) integrated with explorer & picker
  - Unified picker mappings (`<leader>f` files, `<leader>fr` grep, buffers/help under snacks; format remains `<leader>ff`)
  - Explorer auto-closes on entering real file buffers to reduce layout noise
- Benefits: Smaller plugin surface, faster perceived startup, consistent UI styling, fewer overlapping abstractions.
- Remaining Evaluation:
  - Consider deprecating Telescope if snacks gains equivalent git/LSP extensions
  - Decide later on broader use of snacks image/statuscolumn polish if needed
  - Optionally add Undotree (see section 7) after assessing refactor workflow frequency

## 7. Undotree Integration (deferred)
- Candidate plugin: `mbbill/undotree`
- Rationale: Visual exploration of persistent undo history, time-travel diff comparisons
- Deferred Because: Core workflows currently satisfied; adds another UI panel; evaluate only if complex refactors make deep history inspection frequent
- Trial Plan (later): Add spec under `lua/plugins/extra/undotree.lua` with `<leader>u` toggle; benchmark memory/perf on large undo histories
