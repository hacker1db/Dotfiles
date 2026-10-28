#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/install/lib/log.sh"
BROWSER_FILE="$DOTFILES/config/browser/current"

ensure_browser_file() {
  if [ ! -f "$BROWSER_FILE" ]; then
    mkdir -p "$(dirname "$BROWSER_FILE")"
    echo "helium" > "$BROWSER_FILE"
  fi
}

require_defaultbrowser() {
  if ! command -v defaultbrowser >/dev/null 2>&1; then
    warning "defaultbrowser is not installed; run install.sh homebrew first"
    return 1
  fi
}

resolve_browser() {
  if [ -n "${DOTFILES_BROWSER:-}" ]; then
    echo "$DOTFILES_BROWSER"
    return
  fi
  ensure_browser_file
  head -n1 "$BROWSER_FILE" | tr -d '\r' | tr -d ' ' || echo "helium"
}

list_browsers() {
  require_defaultbrowser || return 1
  defaultbrowser
}

write_browser_file() {
  local browser="$1"
  ensure_browser_file
  echo "$browser" > "$BROWSER_FILE"
  info "Browser recorded: $browser"
}

apply_browser() {
  local browser="$1"
  require_defaultbrowser || return 1
  if ! defaultbrowser 2>/dev/null | tr -d '* ' | grep -qx "$browser"; then
    warning "Browser not registered with macOS: $browser"
    info "Registered browsers:"
    defaultbrowser
    return 1
  fi
  write_browser_file "$browser"
  defaultbrowser "$browser" || true
  success "Default browser applied: $browser"
}

if [ "${1:-}" = "browser" ]; then
  shift
fi

case "${1:-sync}" in
  list) list_browsers ;;
  current) resolve_browser ;;
  apply)
    shift || { error "Browser name required"; }
    apply_browser "${1:?browser name}"
    ;;
  sync)
    apply_browser "$(resolve_browser)"
    ;;
  *)
    echo "Usage: browser {list|current|apply <name>|sync}" >&2
    exit 1
    ;;
esac
