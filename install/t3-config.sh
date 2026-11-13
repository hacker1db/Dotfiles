#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "${1:-}" == t3-config ]]; then
    shift
fi
userdata="$HOME/.t3/userdata"
dry_run=0
check=0
for arg in "$@"; do
    [[ "$arg" == --dry-run ]] && dry_run=1
    [[ "$arg" == --check ]] && check=1
done
link_status=0
for name in client-settings.json keybindings.json; do
    source="$root/config/t3code/$name"
    target="$userdata/$name"
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        echo "$name: linked"
        continue
    fi
    if (( check )); then
        echo "$name: not linked to $source"
        link_status=2
        continue
    fi
    if (( dry_run )); then
        echo "Would link: $target -> $source"
        continue
    fi
    mkdir -p "$userdata"
    if [[ -e "$target" || -L "$target" ]]; then
        backup="$target.backup-$(date +%Y%m%d%H%M%S)"
        mv "$target" "$backup"
        echo "Backup: $backup"
    fi
    ln -s "$source" "$target"
    echo "Linked: $target -> $source"
done
provider_status=0
python3 "$root/bin/t3-config" providers --dotfiles-root "$root" "$@" || provider_status=$?
(( provider_status )) && exit "$provider_status"
exit "$link_status"
