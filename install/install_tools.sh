#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/env.sh"

if ! load_brew_env; then
  echo Installing Homebrew
  /bin/bash -c "$(curl --proto "=https" --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew_env || { echo "Homebrew installed but brew is not on PATH" >&2; exit 1; }
fi

export HOMEBREW_NO_ASK=1

BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/brewfile"
[[ -s "$BREWFILE" ]] || { echo "Brewfile missing or empty at $BREWFILE" >&2; exit 1; }

if [[ "${DOTFILES_DEFER_PROMPTS:-0}" == 1 && "$(uname -s)" == Darwin ]]; then
  deferred="$(deferred_installs_file)"
  mkdir -p "$(dirname "$deferred")"
  printf '%s\n' brew-bundle > "$deferred"
  mas_ids="$(sed -nE 's/^mas .*id: ([0-9]+).*/\1/p' "$BREWFILE" | tr '\n' ' ')"
  if ! SUDO_ASKPASS=/usr/bin/false HOMEBREW_BUNDLE_MAS_SKIP="$mas_ids" brew bundle install --file="$BREWFILE"; then
    casks="$(brew bundle list --file="$BREWFILE" --cask | tr '\n' ' ')"
    HOMEBREW_BUNDLE_MAS_SKIP="$mas_ids" HOMEBREW_BUNDLE_CASK_SKIP="$casks" \
      brew bundle check --file="$BREWFILE" --no-upgrade
  fi
  echo "Bundle will finish installation and cleanup in the deferred step."
else
  brew bundle install --file="$BREWFILE"
  brew bundle cleanup --file="$BREWFILE" --brews --cask --tap --mas --force
fi

# Claude Code comes from the native installer (auto-updates in ~/.local/bin); the claude cask is the desktop app.
[ -x "$HOME/.local/bin/claude" ] || curl --proto "=https" --tlsv1.2 -fsSL https://claude.ai/install.sh | bash || true

# Terraform setup
if command -v tfenv >/dev/null 2>&1; then
  tfenv install latest || true
  tfenv use latest || true
fi

# Node / JS toolchain
if command -v nvm >/dev/null 2>&1; then
  nvm install --lts || true
  nvm use --lts || true
fi

if command -v pnpm >/dev/null 2>&1; then
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
  mkdir -p "$PNPM_HOME"
  export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"
  npm install --global --ignore-scripts yarn || true
  yarn global add expo-cli || true
  pnpm add --global vercel || true
  pnpm add --global typescript typescript-language-server eslint prettier @github/copilot || true
fi

# Wordlists
if [ ! -d "$HOME/wordlists" ]; then
  git clone https://github.com/danielmiessler/SecLists.git "$HOME/wordlists" || true
fi

# Go tools
if command -v go >/dev/null 2>&1; then
  go install github.com/air-verse/air@latest || true
  go install github.com/charmbracelet/glow@latest || true
fi

# GitHub extensions
if command -v gh >/dev/null 2>&1; then
  gh auth status >/dev/null 2>&1 || gh auth login || true
  gh extension install dlvhdr/gh-dash || true
  gh extension install advanced-security/gh-sbom || true
  gh extension install github/gh-stack || true
fi

echo Tool install complete

bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/verify.sh"
