#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "${1:-}" == t3-config ]]; then
    shift
fi
exec python3 "$root/bin/t3-config" providers --dotfiles-root "$root" "$@"
