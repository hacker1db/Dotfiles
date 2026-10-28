#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR"
source "$DOTFILES/install/lib/log.sh"
source "$DOTFILES/install/lib/env.sh"

usage() {
  echo "Usage: $(basename "$0") {backup|link|git|homebrew|shell|terminfo|macos|extras|node-tools|nvimtmux|dotnet|dotnet-tools|theme|browser|deferred|all}" >&2
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
    browser) echo "$DOTFILES/install/browser.sh" ;;
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
    link) [ "${DOTFILES_LINK_PHASE:-all}" = files ] || github_ssh_preflight || true ;;
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
  for part in backup link-files homebrew link-integrations terminfo node-tools git macos extras nvimtmux dotnet dotnet-tools theme browser deferred shell; do
    info "Executing $part"
    case "$part" in
      link-files) step=link; export DOTFILES_LINK_PHASE=files ;;
      link-integrations) step=link; export DOTFILES_LINK_PHASE=integrations ;;
      *) step="$part"; unset DOTFILES_LINK_PHASE ;;
    esac
    if ! run_script "$step"; then
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
