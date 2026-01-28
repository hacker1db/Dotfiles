#!/usr/bin/env bash

DOTFILES=$HOME/.dotfiles

if [[ -x "$(command -v gh)" ]]; then
  if ! gh auth status &>/dev/null; then
    echo "Authenticating GitHub CLI"
    gh auth login
  fi
fi

# GitHub account presets
# Signing keys are fetched from 1Password at runtime via op CLI
declare -A ACCOUNTS
ACCOUNTS=(
  [work_name]="CyberDSO"
  [work_email]="177144687+CyberDSO@users.noreply.github.com"
  [work_github]="CyberDSO"
  [work_op_item]="rhzyv3646qyctexiftyrxmb2qe"
  [work_op_vault]="Work"
  [personal_name]="hacker1db"
  [personal_email]="6212228+hacker1db@users.noreply.github.com"
  [personal_github]="hacker1db"
  [personal_op_item]="Github personal"
  [personal_op_vault]="Private"
)

# Fetch SSH signing key from 1Password
fetch_signing_key() {
  local item="$1"
  local vault="$2"
  if ! command -v op &>/dev/null; then
    echo ""
    return 1
  fi
  op item get "$item" --vault "$vault" --fields "public key" 2>/dev/null
}

# Support non-interactive mode
if [ "${DOTFILES_NONINTERACTIVE:-0}" = "1" ]; then
  name=$(git config user.name)
  email=$(git config user.email)
  github=$(git config github.user)
  signingkey=$(git config user.signingkey)
else
  echo ""
  echo "Select a GitHub account:"
  echo "  1) Work     - ${ACCOUNTS[work_name]} (${ACCOUNTS[work_email]})"
  echo "  2) Personal - ${ACCOUNTS[personal_name]} (${ACCOUNTS[personal_email]})"
  echo "  3) Custom"
  echo ""
  read -rp "Account [1/2/3]: " account_choice

  case "$account_choice" in
    1)
      name="${ACCOUNTS[work_name]}"
      email="${ACCOUNTS[work_email]}"
      github="${ACCOUNTS[work_github]}"
      vault="${ACCOUNTS[work_op_vault]}"
      echo "Fetching signing key from 1Password (${ACCOUNTS[work_op_vault]} vault)..."
      signingkey=$(fetch_signing_key "${ACCOUNTS[work_op_item]}" "${ACCOUNTS[work_op_vault]}")
      ;;
    2)
      name="${ACCOUNTS[personal_name]}"
      email="${ACCOUNTS[personal_email]}"
      github="${ACCOUNTS[personal_github]}"
      vault="${ACCOUNTS[personal_op_vault]}"
      echo "Fetching signing key from 1Password (${ACCOUNTS[personal_op_vault]} vault)..."
      signingkey=$(fetch_signing_key "${ACCOUNTS[personal_op_item]}" "${ACCOUNTS[personal_op_vault]}")
      ;;
    *)
      defaultName=$(git config user.name)
      defaultEmail=$(git config user.email)
      defaultGithub=$(git config github.user)
      defaultSigningkey=$(git config user.signingkey)
      read -rp "Name [$defaultName] " name
      read -rp "Email [$defaultEmail] " email
      read -rp "Github username [$defaultGithub] " github
      read -rp "SSH signing key [$defaultSigningkey] " signingkey
      read -rp "1Password vault [Work] " vault
      name="${name:-$defaultName}"
      email="${email:-$defaultEmail}"
      github="${github:-$defaultGithub}"
      signingkey="${signingkey:-$defaultSigningkey}"
      vault="${vault:-Work}"
      ;;
  esac

  if [ -z "$signingkey" ] && [ "$account_choice" != "3" ]; then
    echo "Warning: Could not fetch signing key from 1Password. Is op CLI authenticated?"
    read -rp "SSH signing key (paste manually): " signingkey
  fi
fi

# Write overrides into ~/.gitconfig-local
LOCAL_FILE="$HOME/.gitconfig-local"
if [ ! -f "$LOCAL_FILE" ]; then
  touch "$LOCAL_FILE"
fi

git config -f "$LOCAL_FILE" user.name "$name"
git config -f "$LOCAL_FILE" user.email "$email"
git config -f "$LOCAL_FILE" github.user "$github"

if [ -n "$signingkey" ]; then
  git config -f "$LOCAL_FILE" user.signingkey "$signingkey"
fi

# Configure 1Password SSH agent vault
if [ -n "$vault" ]; then
  AGENT_TOML="$DOTFILES/config/1Password/ssh/agent.toml"
  mkdir -p "$(dirname "$AGENT_TOML")"
  cat > "$AGENT_TOML" <<EOF
# More examples can be found here:
#  https://developer.1password.com/docs/ssh/agent/config
[[ssh-keys]]
vault = "$vault"

# Cache SSH key approvals for 8 hours (28800 seconds)
[agent]
sign_timeout = 28800
EOF
  echo "1Password SSH agent configured for vault: $vault"
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
