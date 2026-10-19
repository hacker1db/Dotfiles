#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT
export HOME="$temp/home with spaces"
export TPM_TEST_LOG="$temp/git.log"
mkdir -p "$HOME" "$temp/bin"
cat > "$temp/bin/git" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == clone && "$2" == git@github.com:tmux-plugins/tpm.git ]]
printf '%s\n' "$2" >> "$TPM_TEST_LOG"
[[ "${TPM_TEST_FAIL:-0}" == 0 ]] || exit 1
mkdir -p "$3/bindings"
touch "$3/tpm" "$3/bindings/install_plugins"
chmod +x "$3/tpm" "$3/bindings/install_plugins"
MOCK
chmod +x "$temp/bin/git"
export PATH="$temp/bin:$PATH"
tpm="$HOME/.config/tmux/plugins/tpm"
bash "$root/install/tmux-plugins.sh"
[[ -x "$tpm/tpm" && -x "$tpm/bindings/install_plugins" ]]
bash "$root/install/tmux-plugins.sh"
[[ "$(wc -l < "$TPM_TEST_LOG" | tr -d ' ')" == 1 ]]
rm "$tpm/bindings/install_plugins"
if bash "$root/install/tmux-plugins.sh"; then
    echo 'Incomplete TPM should fail' >&2
    exit 1
fi
[[ -f "$tpm/tpm" ]]
[[ "$(wc -l < "$TPM_TEST_LOG" | tr -d ' ')" == 1 ]]
rm -r "$tpm"
if TPM_TEST_FAIL=1 bash "$root/install/tmux-plugins.sh"; then
    echo 'Clone failure should fail' >&2
    exit 1
fi
bash "$root/install/tmux-plugins.sh"
[[ -x "$tpm/tpm" ]]
echo 'tmux-plugins tests passed'
