#!/usr/bin/env zsh
set -uo pipefail
source "${0:A:h}/lib.zsh"

BREWFILE="${0:A:h}/brewfile"
defer="${DOTFILES_DEFER_PROMPTS:-0}"

brewfile_items() { sed -nE "s/^$1 \"([^\"]+)\".*/\\1/p" "$BREWFILE" }

defer_item() {
    local deferred
    deferred="$(deferred_installs_file)"
    mkdir -p "${deferred:h}"
    print "$1" >> "$deferred"
}

run_deferred() {
    local deferred item
    local -a items remaining
    deferred="$(deferred_installs_file)"
    [[ -s "$deferred" ]] || { print "No deferred installs"; return 0 }
    load_brew_env || { error "brew not found"; return 1 }
    items=(${(f)"$(<"$deferred")"})
    print "Running installs that need a password: $items"
    remaining=()
    for item in $items; do
        case "$item" in
            mas:*) mas install "${item#mas:}" || remaining+=("$item") ;;
            *) brew install --cask "$item" || remaining+=("$item") ;;
        esac
    done
    if [[ "${#remaining}" -gt 0 ]]; then
        print -l -- $remaining > "$deferred"
        print -u2 "Still not installed: $remaining; rerun with ./install.sh deferred"
        return 1
    fi
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
[[ -f "$BREWFILE" ]] || { error "Brewfile not found at $BREWFILE"; exit 1 }

typeset line tap url formula cask app deferred
for line in ${(f)"$(sed -nE 's/^tap "([^"]+)"(, "([^"]+)")?.*/\1'$'\t''\3/p' "$BREWFILE")"}; do
    tap="${line%%$'\t'*}"
    url="${line#*$'\t'}"
    [[ "$url" == "$line" ]] && url=""
    brew tap "$tap" ${url:+"$url"} || true
    brew trust --tap "$tap" || true
done

for formula in ${(f)"$(brewfile_items brew)"}; do
    brew install --formula "$formula" || true
done

if [[ "$OSTYPE" == darwin* ]]; then
    if [[ "$defer" == 1 ]]; then
        deferred="$(deferred_installs_file)"; mkdir -p "${deferred:h}"; : > "$deferred"
    fi
    for cask in ${(f)"$(brewfile_items cask)"}; do
        if [[ "$defer" == 1 ]]; then
            SUDO_ASKPASS=/usr/bin/false brew install --cask "$cask" || defer_item "$cask"
        else
            brew install --cask "$cask" || true
        fi
    done
    if command -v mas >/dev/null 2>&1; then
        for app in ${(f)"$(sed -nE 's/^mas .*id: ([0-9]+).*/\1/p' "$BREWFILE")"}; do
            [[ "$defer" == 1 ]] && defer_item "mas:$app" || mas install "$app" || true
        done
    fi
    [[ "$defer" == 1 && -s "$(deferred_installs_file)" ]] &&
        print "Deferred installs that need a password: $(tr '\n' ' ' < "$(deferred_installs_file)")"
fi

[[ -x "$HOME/.local/bin/claude" ]] || curl --proto "=https" --tlsv1.2 -fsSL https://claude.ai/install.sh | bash || true

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
