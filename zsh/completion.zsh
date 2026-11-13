# matches case insensitive for lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

# default to file completion
zstyle ':completion:*' completer _expand _complete _files _correct _approximate

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'


# sesh completion
eval "$(sesh completion zsh)"

# skillctl completion (the launcher reuses the last build for completion requests)
if command -v skillctl &> /dev/null; then
    _skillctl_completion="$(skillctl completion zsh 2>/dev/null)" && [[ -n $_skillctl_completion ]] && eval "$_skillctl_completion"
    unset _skillctl_completion
fi

# T3 Code completion. `t3 --completions zsh` takes ~0.4s, so cache it and
# regenerate only when the t3 runtime changes (t3m's completion lives in zsh/functions/_t3m).
if command -v t3 &> /dev/null; then
    _t3_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/_t3_completion.zsh"
    _t3_bin="${T3CODE_HOME:-$HOME/.t3}/runtime/versions"
    if [[ ! -s $_t3_cache || $_t3_bin -nt $_t3_cache ]]; then
        mkdir -p "${_t3_cache:h}"
        t3 --completions zsh > "$_t3_cache" 2>/dev/null || rm -f "$_t3_cache"
    fi
    [[ -s $_t3_cache ]] && source "$_t3_cache"
    unset _t3_cache _t3_bin
fi

# Moved auto help load stuff for me
if [[ -n $HOMEBREW_PREFIX && -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    bindkey '^w' autosuggest-execute
    bindkey '^e' autosuggest-accept
    bindkey '^u' autosuggest-toggle
fi
if [[ -n $HOMEBREW_PREFIX && -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
bindkey '^L' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search


