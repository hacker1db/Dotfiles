#!/usr/bin/env bash

set -euo pipefail

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
TARGET_HOME=${1:-$HOME}
SOURCES=(
    "$DOTFILES/global/AGENTS.md"
    "$DOTFILES/global/AGENTS.md"
    "$DOTFILES/global/AGENTS.md"
)
DESTINATIONS=(
    "$TARGET_HOME/.codex/AGENTS.md"
    "$TARGET_HOME/.copilot/copilot-instructions.md"
    "$TARGET_HOME/.config/opencode/AGENTS.md"
)

for index in "${!SOURCES[@]}"; do
    source_file=${SOURCES[$index]}
    destination=${DESTINATIONS[$index]}
    if [[ ! -f "$source_file" ]]; then
        echo "Missing instruction source: $source_file" >&2
        exit 1
    fi
    if [[ -d "$destination" ]]; then
        echo "Instruction destination is a directory: $destination" >&2
        exit 1
    fi
done

for index in "${!SOURCES[@]}"; do
    source_file=${SOURCES[$index]}
    destination=${DESTINATIONS[$index]}
    if [[ "$source_file" -ef "$destination" ]]; then
        echo "Instruction file already linked: $destination"
        continue
    fi
    mkdir -p "$(dirname "$destination")"
    if [[ -e "$destination" || -L "$destination" ]]; then
        backup_base="$destination.backup.$(date +%Y%m%d%H%M%S)"
        backup=$backup_base
        suffix=0
        while [[ -e "$backup" || -L "$backup" ]]; do
            suffix=$((suffix + 1))
            backup="$backup_base.$suffix"
        done
        mv "$destination" "$backup"
        echo "Preserved existing instruction file: $backup"
    fi
    ln -s "$source_file" "$destination"
    echo "Linked $destination -> $source_file"
done
