if [[ -x /opt/homebrew/bin/brew ]]; then
    _brew_env="$(cd -q / && /opt/homebrew/bin/brew shellenv zsh)" && eval "$_brew_env"
    unset _brew_env
fi
[[ -n $HOMEBREW_PREFIX ]] || return
# source z.sh if it exists
zpath="$HOMEBREW_PREFIX/etc/profile.d/z.sh"
if [ -f "$zpath" ]; then
    source "$zpath"
fi

[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export ANDROID_NDK_HOME="$HOMEBREW_PREFIX/share/android-ndk"
# Gcloud
[[ -r "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc" ]] && source "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc"
[[ -r "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc"
[[ -r "$HOMEBREW_PREFIX/etc/bash_completion.d/az" ]] && source "$HOMEBREW_PREFIX/etc/bash_completion.d/az"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
