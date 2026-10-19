#!/usr/bin/env zsh
# Record and apply the shared theme across tmux, Ghostty, Starship, and Neovim.
# Neovim needs no per-apply edit: config/nvim/lua/core/colorscheme.lua reads the
# theme file at startup.
set -euo pipefail
source "${0:A:h}/lib.zsh"

THEME_FILE="$DOTFILES/config/theme/current"

sed_inplace() {
    if [[ "$OSTYPE" == darwin* ]]; then sed -i '' "$@"; else sed -i "$@"; fi
}

resolve_theme() {
    [[ -n "${DOTFILES_THEME:-}" ]] && { print "$DOTFILES_THEME"; return }
    head -n1 "$THEME_FILE" 2>/dev/null | tr -d '\r ' || print "eldritch"
}

list_themes() {
    local tmux_themes ghostty_themes
    tmux_themes="$(find "$DOTFILES/config/tmux/themes" -maxdepth 1 -name '*.conf' -exec basename {} .conf \; 2>/dev/null | tr '[:upper:]' '[:lower:]')" || true
    ghostty_themes="$(find "$DOTFILES/config/ghostty/themes" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | tr '[:upper:]' '[:lower:]')" || true
    printf "%s\n%s" "$tmux_themes" "$ghostty_themes" | awk 'NF' | sort -u
}

apply_tmux() {
    local theme="$1" tmux_dir="$DOTFILES/config/tmux/themes"
    [[ -f "$tmux_dir/${theme}.conf" ]] || { warning "tmux theme not found: $theme"; return }
    ln -sfn "${theme}.conf" "$tmux_dir/current.conf"
    if grep -q 'themes/eldritch.conf' "$DOTFILES/config/tmux/tmux.conf"; then
        sed_inplace 's/themes\/eldritch.conf/themes\/current.conf/' "$DOTFILES/config/tmux/tmux.conf" || true
    fi
    if [[ -n "${TMUX:-}" ]]; then
        tmux source-file "$HOME/.dotfiles/main/config/tmux/tmux.conf" || warning "tmux reload failed"
    fi
    info "Applied tmux theme: $theme"
}

set_config_line() {
    local file="$1" match="$2" pattern="$3" line="$4" label="$5"
    if grep -q "$match" "$file"; then
        sed_inplace -E "s/${pattern}/${line}/" "$file" || true
        info "Updated $label"
    else
        printf '\n%s\n' "$line" >> "$file"
        info "Added $label"
    fi
}

apply_ghostty() {
    set_config_line "$DOTFILES/config/ghostty/config" '^[Tt]heme' \
        '^theme[[:space:]]*=.*' "theme = ${(C)1}" "Ghostty theme: ${(C)1}"
}

apply_starship() {
    set_config_line "$DOTFILES/config/starship/starship.toml" '^palette =' \
        '^palette[[:space:]]*=[[:space:]]*".*"' "palette = \"$1\"" "Starship palette: $1"
}

apply_all() {
    local theme="$1"
    mkdir -p "${THEME_FILE:h}"
    print "$theme" > "$THEME_FILE"
    info "Theme recorded: $theme"
    apply_tmux "$theme"
    apply_ghostty "$theme"
    apply_starship "$theme"
    success "Theme applied: $theme"
}

[[ "${1:-}" == theme ]] && shift

case "${1:-sync}" in
    list) list_themes ;;
    current) resolve_theme ;;
    apply) shift || error "Theme name required"; apply_all "${1:?theme name}" ;;
    sync) apply_all "$(resolve_theme)" ;;
    *) print -u2 "Usage: theme {list|current|apply <name>|sync}"; exit 1 ;;
esac
