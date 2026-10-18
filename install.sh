#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR"
source "$DOTFILES/install/lib/log.sh"
source "$DOTFILES/install/lib/env.sh"

usage() {
  echo "Usage: $(basename "$0") {backup|link|git|homebrew|shell|terminfo|macos|extras|node-tools|nvimtmux|dotnet|dotnet-tools|theme|deferred|all}" >&2
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
    dotnet-tools) echo "$DOTFILES/install/dotnet-tools.sh" ;;
    theme) echo "$DOTFILES/install/theme.sh" ;;
    deferred) echo "$DOTFILES/install/deferred.sh" ;;
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
  load_brew_env || true
  case "$1" in
    link) github_ssh_preflight || true ;;
  esac
  bash "$sc" "$@"
  local status=$?
  case "$1" in
    link|git) unset GITHUB_SSH_OK ;;
  esac
  load_brew_env || true
  return "$status"
}

if [ "$cmd" = "all" ]; then
  title "Running full install"
  failed=()
  export DOTFILES_DEFER_PROMPTS=1
  for part in backup homebrew link terminfo node-tools git macos extras nvimtmux dotnet dotnet-tools theme deferred shell; do
    info "Executing $part"
    if ! run_script "$part"; then
      if [ "$part" = homebrew ]; then
        error "homebrew failed; the remaining steps need its tools, stopping"
        exit 1
      fi
      error "$part failed; continuing"
      failed+=("$part")
    fi
  done
  echo
  if [ "${#failed[@]}" -gt 0 ]; then
    error "Finished with failures: ${failed[*]}"
    exit 1
  fi
  success "All tasks complete"
  exit 0
fi

run_script "$cmd" "$@"

echo
success "Done."
