#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/env.sh"

deferred="$(deferred_casks_file)"
if [[ ! -s "$deferred" ]]; then
  echo "No deferred casks"
  exit 0
fi

load_brew_env || { echo "brew not found" >&2; exit 1; }

casks=()
while IFS= read -r c; do
  [[ -n "$c" ]] && casks+=("$c")
done < "$deferred"

echo "Installing casks that need a password: ${casks[*]}"
remaining=()
for c in "${casks[@]}"; do
  brew install --cask "$c" || remaining+=("$c")
done

if [[ "${#remaining[@]}" -gt 0 ]]; then
  printf '%s\n' "${remaining[@]}" > "$deferred"
  echo "Casks still not installed: ${remaining[*]}; rerun with ./install.sh deferred" >&2
  exit 1
fi
rm -f "$deferred"
echo "Deferred casks installed"
