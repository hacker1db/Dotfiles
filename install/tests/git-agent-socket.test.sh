#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fixture="$(mktemp -d)"
trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$fixture"' EXIT
mac="$fixture/home/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
linux="$fixture/home/.1password/agent.sock"
forwarded="$fixture/forwarded.sock"
mkdir -p "$(dirname "$mac")" "$(dirname "$linux")"

listen() {
    python3 -c 'import socket,sys,time; s=socket.socket(socket.AF_UNIX); s.bind(sys.argv[1]); s.listen(); time.sleep(60)' "$1" &
    for _ in $(seq 50); do [[ -S "$1" ]] && return; sleep 0.1; done
    echo "socket $1 never appeared" >&2; exit 1
}
check() {
    local got
    got="$(HOME="$fixture/home" SSH_AUTH_SOCK="${3:-}" "$root/bin/git-agent-socket" 2>/dev/null)" || got="<fail>"
    [[ "$got" == "$2" ]] || { echo "FAIL $1: expected '$2', got '$got'" >&2; exit 1; }
    echo "ok $1"
}

check "no agent anywhere" "<fail>"
listen "$forwarded"
check "forwarded agent over SSH" "$forwarded" "$forwarded"
listen "$linux"
check "Linux 1Password app wins over forwarding" "$linux" "$forwarded"
listen "$mac"
check "macOS 1Password app wins" "$mac" "$forwarded"

# End to end on the Linux path: a real agent there must serve git-agent-key.
e2e="$fixture/e2e-home"
mkdir -p "$e2e/.1password"
eval "$(ssh-agent -a "$e2e/.1password/agent.sock")" >/dev/null
trap 'kill $(jobs -p) 2>/dev/null; ssh-agent -k >/dev/null 2>&1; rm -rf "$fixture"' EXIT
ssh-keygen -q -t ed25519 -N '' -C 'Test Key' -f "$fixture/id"
ssh-add -q "$fixture/id" 2>/dev/null
expected="$(cut -d' ' -f1,2 "$fixture/id.pub")"
got="$(HOME="$e2e" SSH_AUTH_SOCK='' "$root/bin/git-agent-key" 'Test Key')"
[[ "$got" == "$expected" ]] || { echo "FAIL git-agent-key: got '$got'" >&2; exit 1; }
echo "ok git-agent-key selects the titled key via the Linux socket"
