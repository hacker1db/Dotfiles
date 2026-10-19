#!/usr/bin/env zsh
# Bootstrap TPM so tmux can install its configured plugins.
set -euo pipefail

tpm="$HOME/.config/tmux/plugins/tpm"

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
