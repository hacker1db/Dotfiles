#!/usr/bin/env bash

[[ -n "$(command -v brew)" ]] && zsh_path="$(brew --prefix)/bin/zsh" || zsh_path="$(which zsh)"
if [[ ! -x "$zsh_path" ]]; then
  zsh_path="$(command -v zsh || true)"
fi
if [[ -z "$zsh_path" ]]; then
  echo "zsh not found, skipping shell setup"
  exit 0
fi

current_user="${USER:-$(id -un)}"
if [[ "$(uname -s)" == "Darwin" ]]; then
  login_shell="$(dscl . -read "/Users/$current_user" UserShell 2>/dev/null | awk '{print $2}')"
else
  login_shell="$(getent passwd "$current_user" | cut -d: -f7)"
fi
[[ -z "$login_shell" ]] && login_shell="$SHELL"

if [[ "$login_shell" == "$zsh_path" ]]; then
  echo "Login shell already $zsh_path"
  echo "Shell setup complete"
  exit 0
fi

if [[ ! -t 0 ]]; then
  echo "Warning: no TTY; cannot change login shell to $zsh_path. Run: chsh -s $zsh_path" >&2
  exit 1
fi

if ! grep -q "$zsh_path" /etc/shells; then
  echo "Adding $zsh_path to /etc/shells"
  echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null || { echo "Failed to update /etc/shells" >&2; exit 1; }
fi
if chsh -s "$zsh_path"; then
  echo "Default shell changed to $zsh_path"
else
  echo "Failed to change default shell to $zsh_path" >&2
  exit 1
fi
echo "Shell setup complete"
