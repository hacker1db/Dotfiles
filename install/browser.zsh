#!/usr/bin/env zsh
set -euo pipefail
source "${0:A:h}/lib.zsh"

BROWSER_FILE="$DOTFILES/config/browser/current"

ensure_browser_file() {
    [[ -f "$BROWSER_FILE" ]] && return 0
    mkdir -p "${BROWSER_FILE:h}"
    print "helium" > "$BROWSER_FILE"
}

require_defaultbrowser() {
    command -v defaultbrowser >/dev/null 2>&1 && return 0
    warning "defaultbrowser is not installed; run install.sh tools first"
    return 1
}

resolve_browser() {
    [[ -n "${DOTFILES_BROWSER:-}" ]] && { print "$DOTFILES_BROWSER"; return }
    ensure_browser_file
    head -n1 "$BROWSER_FILE" | tr -d '\r ' || print "helium"
}

list_browsers() {
    require_defaultbrowser || return 1
    defaultbrowser
}

write_browser_file() {
    local browser="$1"
    ensure_browser_file
    print "$browser" > "$BROWSER_FILE"
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

case "${1:-sync}" in
    list) list_browsers ;;
    current) resolve_browser ;;
    apply)
        shift
        apply_browser "${1:?browser name}"
        ;;
    sync) apply_browser "$(resolve_browser)" ;;
    *)
        print -u2 "Usage: browser {list|current|apply <name>|sync}"
        exit 1
        ;;
esac
