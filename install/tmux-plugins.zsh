#!/usr/bin/env zsh
set -euo pipefail

plugins_dir="$HOME/.local/share/tmux/plugins"
tpm="$plugins_dir/tpm"

if [[ ! -e "$plugins_dir" ]]; then
    for legacy in "$HOME/.config/tmux/plugins" "$HOME"/.dotfiles/*/config/tmux/plugins(N-/); do
        [[ -x "$legacy/tpm/tpm" && -x "$legacy/tpm/bindings/install_plugins" ]] || continue
        mkdir -p "${plugins_dir:h}"
        cp -R "$legacy/." "$plugins_dir"
        print "Copied existing tmux plugins from $legacy to $plugins_dir"
        break
    done
fi

if [[ -e "$tpm" || -L "$tpm" ]]; then
    if [[ ! -x "$tpm/tpm" || ! -x "$tpm/bindings/install_plugins" ]]; then
        print -u2 "TPM at $tpm is incomplete; preserve or repair it before rerunning installation."
        exit 1
    fi
    print "TPM is already installed at $tpm"
    exit 0
fi

mkdir -p "${tpm:h}"
git clone git@github.com:tmux-plugins/tpm.git "$tpm"
[[ -x "$tpm/tpm" && -x "$tpm/bindings/install_plugins" ]] || {
    print -u2 "TPM installation is incomplete at $tpm"
    exit 1
}
print "TPM installed. Reload tmux and press Ctrl+a, then Shift+i to install configured plugins."
