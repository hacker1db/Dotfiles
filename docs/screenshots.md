# Screenshots

`docs/screenshot.png` is recorded with [VHS](https://github.com/charmbracelet/vhs) (`brew install vhs`), which is not in the Brewfile. Regenerate it from the worktree root:

```zsh
vhs docs/screenshot.tape
```

The tape needs `tmux`, `nvim`, `eza`, `bat`, and the JetBrainsMono Nerd Font. It records the current checkout, so the branch name and recent commits appear in the output; record from `main` for the published image.
