#!/usr/bin/env zsh
set -uo pipefail
source "${0:A:h}/lib.zsh"

title "Setting up Node global tools"
if ! ensure_pnpm; then
    warning "pnpm install failed, skipping Node global tools"
    exit 0
fi

typeset -a tools=(
    "@azure/static-web-apps-cli" "@github/copilot" "@readwise/cli"
    bmad-method eslint markdownlint-cli2 md-to-pdf
    obsidian-headless # ob CLI: Obsidian Sync without the desktop app (servers)
    prettier typescript typescript-language-server vercel
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
