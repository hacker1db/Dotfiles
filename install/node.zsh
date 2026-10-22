#!/usr/bin/env zsh
set -uo pipefail
source "${0:A:h}/lib.zsh"

title "Setting up Node global tools"
if ! command -v pnpm >/dev/null 2>&1; then
    print "pnpm not found, skipping Node global tools"
    exit 0
fi

export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
mkdir -p "$PNPM_HOME"
export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"

typeset -a tools=(
    "@azure/static-web-apps-cli" "@github/copilot" "@openai/codex-security" "@readwise/cli"
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

if command -v codex-security >/dev/null 2>&1 && ! codex-security login status >/dev/null 2>&1; then
    if [[ -t 0 ]]; then
        codex-security login || warning "Codex Security login failed; run 'codex-security login' manually"
    else
        print "Skipping Codex Security login: no TTY. Run 'codex-security login' manually"
    fi
fi

success "Node global tools setup complete"
