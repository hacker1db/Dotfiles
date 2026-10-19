#!/usr/bin/env bash
# Make ~/.config/opencode a real directory whose managed entries link into this repo.
# skillctl installs subagents into its agent/ directory and refuses symlinked parents,
# so the directory itself must not be a symlink into the repo.
#
# Usage: opencode-config.sh [target-home]

set -euo pipefail

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
TARGET_HOME=${1:-$HOME}
src="$DOTFILES/config/opencode"
dest="$TARGET_HOME/.config/opencode"
# skillctl owns agent/; the rest is runtime state OpenCode writes into its config directory.
unmanaged=" agent node_modules package.json package-lock.json bun.lock service.json "

if [[ -L "$dest" ]]; then
    rm "$dest"
    echo "Replaced the $dest symlink with a directory"
fi
mkdir -p "$dest"

shopt -s dotglob nullglob
for entry in "$src"/*; do
    name=$(basename "$entry")
    [[ "$unmanaged" == *" $name "* ]] && continue
    target="$dest/$name"
    if [[ -L "$target" && "$entry" -ef "$target" ]]; then
        continue
    elif [[ -L "$target" || ! -e "$target" ]]; then
        ln -sfn "$entry" "$target"
        echo "Linked $target -> $entry"
    else
        echo "$target exists and is not a symlink; skipping."
    fi
done
