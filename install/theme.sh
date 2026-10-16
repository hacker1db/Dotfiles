#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/install/lib/log.sh"
THEME_FILE="$DOTFILES/config/theme/current"

ensure_theme_file() {
  if [ ! -f "$THEME_FILE" ]; then
    mkdir -p "$(dirname "$THEME_FILE")"
    echo "eldritch" > "$THEME_FILE"
  fi
}

resolve_theme() {
  if [ -n "${DOTFILES_THEME:-}" ]; then
    echo "$DOTFILES_THEME"
    return
  fi
  ensure_theme_file
  head -n1 "$THEME_FILE" | tr -d '\r' | tr -d ' ' || echo "eldritch"
}

list_themes() {
  local tmux_themes ghostty_themes
  tmux_themes=$(find "$DOTFILES/config/tmux/themes" -maxdepth 1 -name '*.conf' -exec basename {} .conf \; 2>/dev/null | tr '[:upper:]' '[:lower:]') || true
  ghostty_themes=$(find "$DOTFILES/config/ghostty/themes" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | tr '[:upper:]' '[:lower:]') || true
  printf "%s\n%s" "$tmux_themes" "$ghostty_themes" | awk 'NF' | sort -u
}

apply_tmux() {
  local theme="$1"
  local tmux_dir="$DOTFILES/config/tmux/themes"
  local target_conf="$tmux_dir/${theme}.conf"
  if [ -f "$target_conf" ]; then
    # create/update current.conf symlink
    ln -sf "$target_conf" "$tmux_dir/current.conf"
    # ensure tmux.conf sources current.conf instead of a fixed theme
    if grep -q 'themes/eldritch.conf' "$DOTFILES/config/tmux/tmux.conf"; then
      sed -i '' 's/themes\/eldritch.conf/themes\/current.conf/' "$DOTFILES/config/tmux/tmux.conf" || true
    fi
    if [ -n "${TMUX:-}" ]; then
      tmux source-file "$HOME/.dotfiles/config/tmux/tmux.conf" || warning "tmux reload failed"
    fi
    info "Applied tmux theme: $theme"
  else
    warning "tmux theme not found: $theme"
  fi
}

apply_ghostty() {
  local theme="$1"
  local ghostty_cfg="$DOTFILES/config/ghostty/config"
  # Portable capitalize first letter (macOS default bash lacks ${var^})
  local theme_display="$theme"
  if command -v awk >/dev/null 2>&1; then
    theme_display=$(printf '%s' "$theme" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  fi
  if grep -qi '^theme' "$ghostty_cfg"; then
    sed -i '' -E "s/^theme\s*=.*/theme = ${theme_display}/" "$ghostty_cfg" || true
    info "Updated Ghostty theme: ${theme_display}"
  else
    echo "theme = ${theme_display}" >> "$ghostty_cfg"
    info "Added Ghostty theme line: ${theme_display}"
  fi
}

apply_starship() {
  local theme="$1"
  local starship_cfg="$DOTFILES/config/starship/starship.toml"
  if grep -q '^palette =' "$starship_cfg"; then
    sed -i '' -E "s/^palette\s*=\s*\".*\"/palette = \"$theme\"/" "$starship_cfg" || true
    info "Starship palette set to $theme"
  else
    printf '\npalette = "%s"\n' "$theme" >> "$starship_cfg"
    info "Appended palette declaration to starship config"
  fi
}

apply_nvim() {
  local theme="$1"
  local loader="$DOTFILES/config/nvim/lua/core/colorscheme.lua"
  if [ ! -f "$loader" ]; then
    cat > "$loader" <<'EOF'
local theme_file = vim.fn.stdpath("config") .. "/../theme/current"
local theme = "eldritch"
local f = io.open(theme_file, "r")
if f then
  local line = f:read("*l")
  f:close()
  if line and #line > 0 then theme = line end
end
pcall(vim.cmd, "colorscheme " .. theme)
EOF
    info "Created Neovim dynamic colorscheme loader"
  fi
  # No file edit needed per apply; loader reads the theme file.
}

write_theme_file() {
  local theme="$1"
  ensure_theme_file
  echo "$theme" > "$THEME_FILE"
  info "Theme recorded: $theme"
}

apply_all() {
  local theme="$1"
  write_theme_file "$theme"
  apply_tmux "$theme"
  apply_ghostty "$theme"
  apply_starship "$theme"
  apply_nvim "$theme"
  success "Theme applied: $theme"
}

case "${1:-}" in
  list) list_themes ;;
  current) resolve_theme ;;
  apply)
    shift || { error "Theme name required"; }
    apply_all "${1:?theme name}"
    ;;
  sync)
    apply_all "$(resolve_theme)"
    ;;
  *)
    echo "Usage: theme {list|current|apply <name>|sync}" >&2
    exit 1
    ;;
esac