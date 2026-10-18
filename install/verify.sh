#!/usr/bin/env bash
set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/log.sh"

login=1
[[ "${1:-}" == --no-login || "${DOTFILES_NONINTERACTIVE:-0}" == 1 ]] && login=0

missing=()
for tool in brew git gh pnpm pandoc; do
    command -v "$tool" > /dev/null 2>&1 || missing+=("$tool")
done
if ! command -v node > /dev/null 2>&1 || (( $(node -p 'process.versions.node.split(".")[0]') < 20 )); then
    missing+=("node (20+)")
fi

if command -v gh > /dev/null 2>&1 && ! gh auth status > /dev/null 2>&1; then
    if (( login )); then
        info "Log in to GitHub to continue."
        gh auth login
    fi
    gh auth status > /dev/null 2>&1 || missing+=("gh login (run gh auth login)")
fi

if (( ${#missing[@]} )); then
    error "Missing: ${missing[*]}"
    exit 1
fi
success "Requirements present and GitHub is logged in."
