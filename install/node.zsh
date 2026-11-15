#!/usr/bin/env zsh
set -uo pipefail
source "${0:A:h}/lib.zsh"

title "Setting up Node global tools"
if ! ensure_pnpm; then
    warning "pnpm install failed, skipping Node global tools"
    exit 0
fi

typeset -a tools=(
    "@azure/static-web-apps-cli@2.1.0" "@github/copilot@1.0.112" "@readwise/cli@0.5.11"
    eslint@10.15.0 markdownlint-cli2@0.24.1 md-to-pdf@5.2.5
    obsidian-headless@0.0.14 # ob CLI: Obsidian Sync without the desktop app (servers)
    prettier@3.10.1 typescript@7.0.2 typescript-language-server@6.1.0 vercel@65.16.0
)
typeset tool
for tool in $tools; do
    print "Installing $tool..."
    pnpm add --global "$tool"
done

if command -v readwise >/dev/null 2>&1; then
    if [[ -t 0 ]]; then
        readwise login || warning "Readwise login failed; run 'readwise login' manually"
    else
        print "Skipping Readwise login: no TTY. Run 'readwise login' manually"
    fi
fi

success "Node global tools setup complete"
