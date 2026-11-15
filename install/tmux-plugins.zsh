#!/usr/bin/env zsh
set -euo pipefail
source "${0:A:h}/lib.zsh"

plugins_dir="$HOME/.local/share/tmux/plugins"
tpm="$plugins_dir/tpm"

if [[ ! -e "$plugins_dir" ]]; then
    for legacy in "$HOME/.config/tmux/plugins" "$HOME"/.dotfiles/*/config/tmux/plugins(N-/) "$HOME"/Developer/dotfiles/*/config/tmux/plugins(N-/); do
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
fi

typeset -A pins=(
    tmux-plugins/tpm e261deb1b47614eed3400089ce7197dc68acc4eb
    tmux-plugins/tmux-yank acfd36e4fcba99f8310a7dfb432111c242fe7392
    tmux-plugins/tmux-battery 43832651ede43f54dcf0588727c1957fe648d57d
    tmux-plugins/tmux-cpu bcb110d754ab2417de824c464730c412a3eb2769
    tmux-plugins/tmux-sensible 25cb91f42d020f675bb0a2ce3fbd3a5d96119efa
    christoomey/vim-tmux-navigator e41c431a0c7b7388ae7ba341f01a0d217eb3a432
    tmux-plugins/tmux-resurrect cff343cf9e81983d3da0c8562b01616f12e8d548
    tmux-plugins/tmux-continuum 0698e8f4b17d6454c71bf5212895ec055c578da0
    wfxr/tmux-fzf-url 7c4838e95fde660b7f2aaf514323ac8498e0d4f4
    joshmedeski/tmux-nerd-font-window-name c4a8baf3dc35707aa568eb2a69e270fc16728b71
)
mkdir -p "$plugins_dir"
typeset repo dest
for repo in ${(ok)pins}; do
    dest="$plugins_dir/${repo#*/}"
    [[ -e "$dest" || -L "$dest" ]] && continue
    pinned_clone "$(github_repo_url "$repo")" "$dest" "${pins[$repo]}" || { print -u2 "Could not install $repo at ${pins[$repo]}"; exit 1 }
    print "Installed $repo at ${pins[$repo]:0:12}"
done
[[ -x "$tpm/tpm" && -x "$tpm/bindings/install_plugins" ]] || {
    print -u2 "TPM installation is incomplete at $tpm"
    exit 1
}
