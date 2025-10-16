#!/usr/bin/env bash

if [[ -x "$(command -v gh)" ]]; then
  if ! gh auth status &>/dev/null; then
    echo "Authenticating GitHub CLI"
    gh auth login
  fi
fi

defaultName=$(git config user.name)
defaultEmail=$(git config user.email)
defaultGithub=$(git config github.user)

# Support non-interactive mode
if [ "${DOTFILES_NONINTERACTIVE:-0}" = "1" ]; then
  name="$defaultName"
  email="$defaultEmail"
  github="$defaultGithub"
else
  read -rp "Name [$defaultName] " name
  read -rp "Email [$defaultEmail] " email
  read -rp "Github username [$defaultGithub] " github
fi

# Write overrides into ~/.gitconfig-local only if it already exists and is a file (do not create here)
LOCAL_FILE="$HOME/.gitconfig-local"
if [ -f "$LOCAL_FILE" ]; then
  git config -f "$LOCAL_FILE" user.name "${name:-$defaultName}"
  git config -f "$LOCAL_FILE" user.email "${email:-$defaultEmail}"
  git config -f "$LOCAL_FILE" github.user "${github:-$defaultGithub}"
fi

if [[ "$(uname)" == "Darwin" ]]; then
  git config --global credential.helper "osxkeychain"
else
  if [ "${DOTFILES_NONINTERACTIVE:-0}" = "1" ]; then
    git config --global credential.helper "cache --timeout 3600"
  else
    read -rn 1 -p "Save user and password to an unencrypted file? [y/N] " save
    echo
    if [[ $save =~ ^([Yy])$ ]]; then
      git config --global credential.helper "store"
    else
      git config --global credential.helper "cache --timeout 3600"
    fi
  fi
fi

echo "Git setup complete"
