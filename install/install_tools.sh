#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/env.sh"

if ! load_brew_env; then
  echo Installing Homebrew
  /bin/bash -c "$(curl --proto "=https" --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew_env || { echo "Homebrew installed but brew is not on PATH" >&2; exit 1; }
fi

export HOMEBREW_NO_ASK=1

# Backup installation for when brew bundle is unreliable; the Brewfile is the
# single source of truth for taps, formulas, casks, and MAS apps.
BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/brewfile"
[ -f "$BREWFILE" ] || { echo "Brewfile not found at $BREWFILE" >&2; exit 1; }

while IFS=$'\t' read -r tap url; do
  if [[ -n "$url" ]]; then
    brew tap "$tap" "$url" || true
  else
    brew tap "$tap" || true
  fi
  brew trust --tap "$tap" || true
done < <(sed -nE 's/^tap "([^"]+)"(, "([^"]+)")?.*/\1'$'\t''\3/p' "$BREWFILE")

while IFS= read -r f; do
  brew install --formula "$f" || true
done < <(sed -nE 's/^brew "([^"]+)".*/\1/p' "$BREWFILE")

CASKS=()
while IFS= read -r c; do
  CASKS+=("$c")
done < <(sed -nE 's/^cask "([^"]+)".*/\1/p' "$BREWFILE")

if [[ "$(uname -s)" == Darwin ]]; then
  if [[ "${DOTFILES_DEFER_PROMPTS:-0}" == 1 ]]; then
    deferred="$(deferred_installs_file)"
    mkdir -p "$(dirname "$deferred")"
    : > "$deferred"
    for c in "${CASKS[@]}"; do
      SUDO_ASKPASS=/usr/bin/false brew install --cask "$c" || echo "$c" >> "$deferred"
    done
    [[ -s "$deferred" ]] && echo "Deferred installs that need a password: $(tr '\n' ' ' < "$deferred")"
  else
    for c in "${CASKS[@]}"; do
      brew install --cask "$c" || true
    done
  fi
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
fi

# MAS apps
if [[ "$(uname -s)" == Darwin ]] && command -v mas >/dev/null 2>&1; then
  while IFS= read -r app; do
    if [[ "${DOTFILES_DEFER_PROMPTS:-0}" == 1 ]]; then
      deferred="$(deferred_installs_file)"
      mkdir -p "$(dirname "$deferred")"
      echo "mas:$app" >> "$deferred"
    else
      mas install "$app" || true
    fi
  done < <(sed -nE 's/^mas .*id: ([0-9]+).*/\1/p' "$BREWFILE")
fi

echo Backup install complete

bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/verify.sh"
