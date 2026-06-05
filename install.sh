#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR"
source "$DOTFILES/install/lib/log.sh"

usage() {
  echo "Usage: $(basename "$0") {backup|link|git|homebrew|shell|terminfo|macos|extras|node-tools|nvimtmux|dotnet|theme|all}" >&2
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

cmd="$1"; shift || true

# Map subcommand to script path
script_for() {
  case "$1" in
    backup) echo "$DOTFILES/install/backup.sh" ;;
    link) echo "$DOTFILES/install/link.sh" ;;
    git) echo "$DOTFILES/install/git.sh" ;;
    homebrew) echo "$DOTFILES/install/install_tools.sh" ;;
    shell) echo "$DOTFILES/install/shell.sh" ;;
    terminfo) echo "$DOTFILES/install/terminfo.sh" ;;
    macos) echo "$DOTFILES/install/osx.sh" ;;
    extras) echo "$DOTFILES/install/extras.sh" ;;
    node-tools) echo "$DOTFILES/install/node-tools.sh" ;;
    nvimtmux) echo "$DOTFILES/install/nvimtmux.sh" ;;
    dotnet) echo "$DOTFILES/install/dotnet.sh" ;;
    theme) echo "$DOTFILES/install/theme.sh" ;;
    *) return 1 ;;
  esac
}

run_script() {
  local sc
  sc="$(script_for "$1")" || usage
  if [ ! -f "$sc" ]; then
    error "Script missing: $sc"
    exit 1
  fi
  source "$sc" "$@"
}

if [ "$cmd" = "all" ]; then
  title "Running full install"
  for part in backup link terminfo homebrew node-tools shell git macos extras nvimtmux dotnet theme; do
    info "Executing $part"
    run_script "$part"
  done
  echo
  success "All tasks complete"
  exit 0
fi

run_script "$cmd" "$@"

echo
success "Done."
