#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"

deferred="$(deferred_installs_file)"
if [[ ! -s "$deferred" ]]; then
  echo "No deferred installs"
  exit 0
fi

load_brew_env || { echo "brew not found" >&2; exit 1; }
BREWFILE="$SCRIPT_DIR/brewfile"
[[ -s "$BREWFILE" ]] || { echo "Brewfile missing or empty: $BREWFILE" >&2; exit 1; }
export HOMEBREW_NO_ASK=1
brew bundle install --file="$BREWFILE"
brew bundle cleanup --file="$BREWFILE" --brews --cask --tap --mas --force
rm -f "$deferred"
echo "Deferred installs complete"
