export HOMEBREW_BREWFILE=~/.dotfiles/install/Brewfile
eval $(/opt/homebrew/bin/brew shellenv)
# source z.sh if it exists
zpath="$(brew --prefix)/etc/profile.d/z.sh"
if [ -f "$zpath" ]; then
    source "$zpath"
fi

[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export ANDROID_NDK_HOME="$(brew --prefix)/share/android-ndk"
# Gcloud
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
source /opt/homebrew/etc/bash_completion.d/az
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
