#!/usr/bin/env zsh
set -uo pipefail
source "${0:A:h}/lib.zsh"

BREWFILE="${0:A:h}/brewfile"
defer="${DOTFILES_DEFER_PROMPTS:-0}"

bundle_sync() {
    brew bundle install --file="$BREWFILE" || return 1
    brew bundle cleanup --file="$BREWFILE" --brews --cask --tap --mas --force
}

run_deferred() {
    local deferred
    deferred="$(deferred_installs_file)"
    [[ -s "$deferred" ]] || { print "No deferred installs"; return 0 }
    load_brew_env || { error "brew not found"; return 1 }
    [[ -s "$BREWFILE" ]] || { error "Brewfile missing or empty: $BREWFILE"; return 1 }
    export HOMEBREW_NO_ASK=1
    print "Finishing Brewfile installation and cleanup"
    bundle_sync || { print -u2 "Bundle did not finish; rerun with ./install.sh deferred"; return 1 }
    rm -f "$deferred"
    print "Deferred installs complete"
}

change_shell() {
    local zsh_path login_shell user="${USER:-$(id -un)}"
    zsh_path="$(brew --prefix 2>/dev/null)/bin/zsh"
    [[ -x "$zsh_path" ]] || zsh_path="${commands[zsh]:-}"
    [[ -n "$zsh_path" ]] || { print "zsh not found, skipping shell setup"; return 0 }
    if [[ "$OSTYPE" == darwin* ]]; then
        login_shell="$(dscl . -read "/Users/$user" UserShell 2>/dev/null | awk '{print $2}')"
    else
        login_shell="$(getent passwd "$user" | cut -d: -f7)"
    fi
    [[ "${login_shell:-$SHELL}" == "$zsh_path" ]] && { print "Login shell already $zsh_path"; return 0 }
    if [[ ! -t 0 ]]; then
        print -u2 "Warning: no TTY; cannot change login shell to $zsh_path. Run: chsh -s $zsh_path"
        return 1
    fi
    if ! grep -q "$zsh_path" /etc/shells; then
        print "Adding $zsh_path to /etc/shells"
        print "$zsh_path" | sudo tee -a /etc/shells >/dev/null || { error "Failed to update /etc/shells"; return 1 }
    fi
    chsh -s "$zsh_path" || { error "Failed to change default shell to $zsh_path"; return 1 }
    print "Default shell changed to $zsh_path"
}

if [[ "${1:-}" == deferred ]]; then
    rc=0
    run_deferred || rc=1
    change_shell || rc=1
    exit $rc
fi

title "Installing Homebrew packages"
if ! load_brew_env; then
    print "Installing Homebrew"
    /bin/bash -c "$(curl --proto "=https" --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_env || { error "Homebrew installed but brew is not on PATH"; exit 1 }
fi
export HOMEBREW_NO_ASK=1
[[ -s "$BREWFILE" ]] || { error "Brewfile missing or empty at $BREWFILE"; exit 1 }

if [[ "$defer" == 1 && "$OSTYPE" == darwin* ]]; then
    typeset deferred mas_ids casks
    deferred="$(deferred_installs_file)"
    mkdir -p "${deferred:h}"
    print brew-bundle > "$deferred"
    mas_ids="$(sed -nE 's/^mas .*id: ([0-9]+).*/\1/p' "$BREWFILE" | tr '\n' ' ')"
    if ! SUDO_ASKPASS=/usr/bin/false HOMEBREW_BUNDLE_MAS_SKIP="$mas_ids" brew bundle install --file="$BREWFILE"; then
        casks="$(brew bundle list --file="$BREWFILE" --cask | tr '\n' ' ')"
        HOMEBREW_BUNDLE_MAS_SKIP="$mas_ids" HOMEBREW_BUNDLE_CASK_SKIP="$casks" \
            brew bundle check --file="$BREWFILE" --no-upgrade ||
            { error "Brewfile formulas and taps are not installed"; exit 1 }
    fi
    print "Bundle will finish installation and cleanup in the deferred pass."
else
    bundle_sync || { error "Brewfile installation failed"; exit 1 }
fi

[[ -x "$HOME/.local/bin/claude" ]] || curl --proto "=https" --tlsv1.2 -fsSL https://claude.ai/install.sh | bash || true

[[ -x "$HOME/.local/bin/codex" ]] || curl --proto "=https" --tlsv1.2 -fsSL https://chatgpt.com/codex/install.sh | sh || true

if command -v tfenv >/dev/null 2>&1; then
    tfenv install latest || true
    tfenv use latest || true
fi

[[ -d "$HOME/wordlists" ]] || git clone https://github.com/danielmiessler/SecLists.git "$HOME/wordlists" || true

if command -v go >/dev/null 2>&1; then
    typeset pkg
    for pkg in github.com/air-verse/air@latest github.com/charmbracelet/glow@latest; do
        go install "$pkg" || true
    done
fi

if command -v gh >/dev/null 2>&1; then
    gh auth status >/dev/null 2>&1 || gh auth login || true
    typeset ext
    for ext in dlvhdr/gh-dash advanced-security/gh-sbom github/gh-stack; do
        gh extension install "$ext" || true
    done
fi

if [[ "$defer" != 1 ]]; then
    run_deferred || true
    change_shell || exit 1
fi
success "Tools setup complete"
