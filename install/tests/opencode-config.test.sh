#!/usr/bin/env bash
# Fixture test for install/opencode-config.sh in a temporary HOME.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT
home="$temp/home"
src="$root/config/opencode"
dest="$home/.config/opencode"
fail() { echo "FAIL: $*" >&2; exit 1; }

# Legacy layout: the whole directory was a symlink into the repo.
mkdir -p "$home/.config"
ln -s "$src" "$dest"
bash "$root/install/opencode-config.sh" "$home" > "$temp/out1" || fail "first run $(cat "$temp/out1")"
[ -d "$dest" ] && [ ! -L "$dest" ] || fail "config dir must be a real directory"
for name in opencode.json cli.json command; do
    [ "$(readlink "$dest/$name")" = "$src/$name" ] || fail "link $name"
done
[ ! -e "$dest/agent" ] && [ ! -L "$dest/agent" ] || fail "agent must be left to skillctl"

# Second run is a no-op; skillctl-owned and unmanaged entries are preserved.
mkdir "$dest/agent"; touch "$dest/agent/fixture.md" "$dest/service.json"
rm "$dest/cli.json"; printf '{}\n' > "$dest/cli.json"
bash "$root/install/opencode-config.sh" "$home" > "$temp/out2" || fail "second run $(cat "$temp/out2")"
grep -q Linked "$temp/out2" && fail "second run relinked: $(cat "$temp/out2")"
grep -q "cli.json exists and is not a symlink" "$temp/out2" || fail "unmanaged file not reported"
[ -f "$dest/agent/fixture.md" ] && [ -f "$dest/service.json" ] && [ ! -L "$dest/cli.json" ] || fail "preserved entries changed"

echo "opencode-config tests passed"
