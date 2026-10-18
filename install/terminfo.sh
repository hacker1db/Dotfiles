#!/usr/bin/env bash

echo "Configuring terminfo"
[ -f "$HOME/.dotfiles/main/resources/tmux.terminfo" ] && tic -x "$HOME/.dotfiles/main/resources/tmux.terminfo"
[ -f "$HOME/.dotfiles/main/resources/xterm-256color-italic.terminfo" ] && tic -x "$HOME/.dotfiles/main/resources/xterm-256color-italic.terminfo"
echo "Terminfo setup complete"