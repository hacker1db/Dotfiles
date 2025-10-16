#!/usr/bin/env bash

echo "Configuring terminfo"
[ -f "$HOME/.dotfiles/resources/tmux.terminfo" ] && tic -x "$HOME/.dotfiles/resources/tmux.terminfo"
[ -f "$HOME/.dotfiles/resources/xterm-256color-italic.terminfo" ] && tic -x "$HOME/.dotfiles/resources/xterm-256color-italic.terminfo"
echo "Terminfo setup complete"