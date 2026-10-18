#!/usr/bin/env bash

DOTFILES=$HOME/.dotfiles/main
LOCAL_FILE="$HOME/.gitconfig-local"
PROFILE_DIR="$DOTFILES/git/profiles"

if [[ -x "$(command -v gh)" ]]; then
  if ! gh auth status &>/dev/null; then
    echo "Authenticating GitHub CLI"
    gh auth login
  fi
fi

[[ -e "$LOCAL_FILE" ]] || touch "$LOCAL_FILE"

link_file() {
  local src="$1" dest="$2"
  if [[ -L "$dest" || ! -e "$dest" ]]; then
    ln -sfn "$src" "$dest"
    echo "Linked $dest -> $src"
  else
    echo "$dest exists and is not a symlink; skipping."
  fi
}

profile="${DOTFILES_GIT_PROFILE:-}"
if [[ -z "$profile" && "${DOTFILES_NONINTERACTIVE:-0}" != "1" ]]; then
  profiles=()
  for dir in "$PROFILE_DIR"/*/; do
    [[ -f "$dir/gitconfig" ]] && profiles+=("$(basename "$dir")")
  done
  if [[ ${#profiles[@]} -gt 0 ]]; then
    echo "Available Git account profiles: ${profiles[*]}"
    read -rp "Profile to enable (blank for none): " profile
  fi
fi

if [[ -n "$profile" ]]; then
  if [[ ! -f "$PROFILE_DIR/$profile/gitconfig" ]]; then
    echo "Unknown Git profile: $profile" >&2
    exit 1
  fi
  link_file "$PROFILE_DIR/$profile/gitconfig" "$HOME/.gitconfig-accounts"
  if [[ -f "$PROFILE_DIR/$profile/ssh_config" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    link_file "$PROFILE_DIR/$profile/ssh_config" "$HOME/.ssh/config-accounts"
  fi
  git config -f "$LOCAL_FILE" --unset-all user.signingkey 2>/dev/null || true
fi

if [[ "${DOTFILES_NONINTERACTIVE:-0}" != "1" ]]; then
  if [[ -z "$(git config --get user.name)" ]]; then
    read -rp "Git user name: " name
    [[ -n "$name" ]] && git config -f "$LOCAL_FILE" user.name "$name"
  fi
  if [[ -z "$(git config --get user.email)" ]]; then
    read -rp "Git user email: " email
    [[ -n "$email" ]] && git config -f "$LOCAL_FILE" user.email "$email"
  fi
fi

echo "Git setup complete"
