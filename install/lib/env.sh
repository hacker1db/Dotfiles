#!/usr/bin/env bash

declare -F warning >/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

load_brew_env() {
  command -v brew >/dev/null 2>&1 && return 0
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

github_ssh_preflight() {
  if [ -n "${GITHUB_SSH_OK:-}" ]; then
    [ "$GITHUB_SSH_OK" = "1" ]
    return
  fi

  local output
  output="$(ssh -T \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new \
    git@github.com 2>&1 || true)"

  case "$output" in
    *"successfully authenticated"*)
      export GITHUB_SSH_OK=1
      return 0
      ;;
  esac

  export GITHUB_SSH_OK=0
  warning "GitHub SSH authentication is not available; GitHub clones will use HTTPS."
  printf '  ssh said: %s\n' "$(printf '%s' "$output" | tail -n 1)" >&2
  case "$output" in
    *"Permission denied"*)
      if [ "$(uname -s)" = "Linux" ] && [ -z "${SSH_AUTH_SOCK:-}" ] && ! ls "$HOME"/.ssh/id_* >/dev/null 2>&1; then
        echo "  This Linux host has no SSH agent (SSH_AUTH_SOCK unset) and no key in ~/.ssh; the 1Password agent socket under ~/Library only exists on macOS." >&2
        echo "  Start an agent and ssh-add a key, or add a key to ~/.ssh and register it on GitHub, then confirm with: ssh -T git@github.com" >&2
      else
        echo "  Unlock 1Password and enable its SSH agent, or add a key with ssh-add, then confirm with: ssh -T git@github.com" >&2
      fi
      ;;
    *"Host key verification failed"*)
      echo "  Verify GitHub's host key in ~/.ssh/known_hosts, then confirm with: ssh -T git@github.com" >&2
      ;;
    *"Could not resolve"* | *"timed out"* | *"Connection refused"*)
      echo "  Check network access to ssh.github.com:443." >&2
      ;;
  esac
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "  Using the authenticated gh CLI as the git credential helper for these clones." >&2
  else
    echo "  Private HTTPS clones need credentials: run gh auth login." >&2
  fi
  return 1
}

github_repo_url() {
  local slug="$1"
  if github_ssh_preflight >&2; then
    printf 'git@github.com:%s.git\n' "$slug"
  else
    printf 'https://github.com/%s.git\n' "$slug"
  fi
}

github_git() {
  export GIT_TERMINAL_PROMPT=0
  if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
    git "$@"
    return
  fi
  if github_ssh_preflight >/dev/null 2>&1; then
    git \
      -c credential.helper= \
      -c 'credential.helper=!gh auth git-credential' \
      "$@"
  else
    git \
      -c credential.helper= \
      -c 'credential.helper=!gh auth git-credential' \
      -c url.https://github.com/.insteadOf=git@github.com: \
      "$@"
  fi
}

github_clone() {
  github_git clone "$@"
}

github_owner() {
  if [ -n "${DOTFILES_GITHUB_OWNER:-}" ]; then
    printf '%s\n' "$DOTFILES_GITHUB_OWNER"
    return
  fi
  local origin owner
  origin="$(git -C "$(dirname "${BASH_SOURCE[0]}")/../.." remote get-url origin 2>/dev/null || true)"
  owner="$(printf '%s' "$origin" | sed -nE 's#^(git@github\.com:|ssh://git@github\.com/|https?://github\.com/)([^/]+)/.*#\2#p')"
  if [ -z "$owner" ] && command -v gh >/dev/null 2>&1; then
    owner="$(gh api user --jq '.login' 2>/dev/null || true)"
  fi
  [ -n "$owner" ] || return 1
  printf '%s\n' "$owner"
}
