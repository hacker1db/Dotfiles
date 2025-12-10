#!/usr/bin/env bash

[[ -n "$(command -v brew)" ]] && zsh_path="$(brew --prefix)/bin/zsh" || zsh_path="$(which zsh)"
if ! grep -q "$zsh_path" /etc/shells; then
  echo "Adding $zsh_path to /etc/shells"
  echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
fi
if [[ "$SHELL" != "$zsh_path" ]]; then
  chsh -s "$zsh_path"
  echo "Default shell changed to $zsh_path"
fi
echo "Shell setup complete"