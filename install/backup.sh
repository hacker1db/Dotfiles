#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/install/lib/log.sh"

BACKUP_DIR="$HOME/dotfiles-backup"

title "Backing up existing dotfiles"
mkdir -p "$BACKUP_DIR"

get_linkables() { find -H "$DOTFILES" -maxdepth 3 -name '*.symlink'; }

for file in $(get_linkables); do
  filename=".$(basename "$file" '.symlink')"
  target="$HOME/$filename"
  if [ -f "$target" ] && [ ! -L "$target" ]; then
    info "Backing up $filename"
    cp "$target" "$BACKUP_DIR" || warning "Failed to copy $target"
  else
    warning "$filename missing or already a symlink"
  fi
done

for filename in "$HOME/.config/nvim" "$HOME/.vim" "$HOME/.vimrc"; do
  if [ -e "$filename" ] && [ ! -L "$filename" ]; then
    info "Backing up $(basename "$filename")"
    cp -R "$filename" "$BACKUP_DIR" || warning "Failed to copy $filename"
  else
    warning "$(basename "$filename") missing or symlink"
  fi
done

success "Backup complete -> $BACKUP_DIR"