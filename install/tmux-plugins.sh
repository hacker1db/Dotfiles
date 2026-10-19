#!/usr/bin/env bash
set -euo pipefail

tpm="$HOME/.config/tmux/plugins/tpm"

if [[ -e "$tpm" || -L "$tpm" ]]; then
    if [[ ! -x "$tpm/tpm" || ! -x "$tpm/bindings/install_plugins" ]]; then
        echo "TPM at $tpm is incomplete; preserve or repair it before rerunning installation." >&2
        exit 1
    fi
    echo "TPM is already installed at $tpm"
    exit 0
fi

mkdir -p "$(dirname "$tpm")"
git clone git@github.com:tmux-plugins/tpm.git "$tpm"
[[ -x "$tpm/tpm" && -x "$tpm/bindings/install_plugins" ]] || {
    echo "TPM installation is incomplete at $tpm" >&2
    exit 1
}
echo "TPM installed. Reload tmux and press Ctrl+a, then Shift+i to install configured plugins."
