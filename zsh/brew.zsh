for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [[ -x "$_brew" ]] || continue
    _brew_env="$(builtin cd -q / && "$_brew" shellenv zsh)" && eval "$_brew_env"
    unset _brew_env
    typeset +x FPATH
    break
done
unset _brew
export HOMEBREW_NO_ASK=1
[[ -n $HOMEBREW_PREFIX ]] || return
# source z.sh if it exists
zpath="$HOMEBREW_PREFIX/etc/profile.d/z.sh"
if [ -f "$zpath" ]; then
    source "$zpath"
fi

[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"  # This loads nvm
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export ANDROID_NDK_HOME="$HOMEBREW_PREFIX/share/android-ndk"
# Gcloud
[[ -r "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc" ]] && source "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc"
[[ -r "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc"
[[ -r "$HOMEBREW_PREFIX/etc/bash_completion.d/az" ]] && source "$HOMEBREW_PREFIX/etc/bash_completion.d/az"
export PATH="$HOMEBREW_PREFIX/opt/mysql-client/bin:$PATH"
