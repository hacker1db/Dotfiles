#!/usr/bin/env bash
set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/env.sh"

login=1
[[ "${DOTFILES_NONINTERACTIVE:-0}" == 1 ]] && login=0

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

use_1password_agent() {
    local sock
    for sock in "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" "$HOME/.1password/agent.sock"; do
        [[ -S "$sock" ]] && export SSH_AUTH_SOCK="$sock" && return
    done
}

unset GITHUB_SSH_OK
if ! github_ssh_preflight > /dev/null 2>&1; then
    use_1password_agent
    unset GITHUB_SSH_OK
    until github_ssh_preflight; do
        if (( ! login )); then
            missing+=("GitHub SSH through the 1Password agent")
            break
        fi
        [[ "$(uname -s)" == Darwin ]] && open -a 1Password 2> /dev/null
        info "Sign in to 1Password, turn on Settings > Developer > Use the SSH agent, and make sure your GitHub SSH key is in it."
        read -r -p "Press Enter to check again, or type skip: " reply || reply=skip
        if [[ "$reply" == skip ]]; then
            missing+=("GitHub SSH through the 1Password agent")
            break
        fi
        use_1password_agent
        unset GITHUB_SSH_OK
    done
fi

if (( ${#missing[@]} )); then
    error "Missing: ${missing[*]}"
    exit 1
fi
success "Tools are installed, GitHub is logged in, and SSH to GitHub works."
