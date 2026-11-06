#!/usr/bin/env zsh
set -euo pipefail
DOTFILES="${0:A:h:h}"
typeset signer="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
if [[ ! -x "$signer" ]]; then
    signer="$(command -v op-ssh-sign || true)"
fi
[[ -n "$signer" ]] || { print -u2 "1Password SSH signer unavailable"; exit 1; }
typeset config="$HOME/.config/git/onepassword.conf"
typeset label="${DOTFILES_SIGNING_KEY_LABEL:-$(git config --get dotfiles.signingKeyLabel || true)}"
if [[ -z "$label" && "${DOTFILES_NONINTERACTIVE:-0}" != 1 && -t 0 ]]; then
    read -r "label?1Password SSH key label (blank requires exactly one agent key): "
fi
mkdir -p "${config:h}"
git config -f "$config" gpg.format ssh
git config -f "$config" gpg.ssh.program "$signer"
git config -f "$config" gpg.ssh.defaultKeyCommand "'${DOTFILES}/bin/git-signing-key'"
git config -f "$config" dotfiles.signingKeyLabel "$label"
git config -f "$config" commit.gpgsign true
git config -f "$config" tag.gpgsign true
if [[ -n "$(git config --get user.signingkey || true)" ]]; then
    print -u2 "Existing user.signingkey overrides dynamic lookup; remove it from its source to enable agent selection."
    exit 1
fi
"$DOTFILES/bin/git-signing-key" >/dev/null
print "1Password signing configured; key material stays in the agent."
