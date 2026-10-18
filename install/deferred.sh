#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/env.sh"

deferred="$(deferred_installs_file)"
if [[ ! -s "$deferred" ]]; then
  echo "No deferred installs"
  exit 0
fi

load_brew_env || { echo "brew not found" >&2; exit 1; }

items=()
while IFS= read -r item; do
  [[ -n "$item" ]] && items+=("$item")
done < "$deferred"

echo "Running installs that need a password: ${items[*]}"
remaining=()
for item in "${items[@]}"; do
  case "$item" in
    mas:*)
      if command -v mas >/dev/null 2>&1; then
        mas install "${item#mas:}" || remaining+=("$item")
      else
        remaining+=("$item")
      fi
      ;;
    *) brew install --cask "$item" || remaining+=("$item") ;;
  esac
done

if [[ "${#remaining[@]}" -gt 0 ]]; then
  printf '%s\n' "${remaining[@]}" > "$deferred"
  echo "Still not installed: ${remaining[*]}; rerun with ./install.sh deferred" >&2
  exit 1
fi
rm -f "$deferred"
echo "Deferred installs complete"
