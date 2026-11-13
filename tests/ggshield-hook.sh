#!/bin/sh
# Checks git/hooks/ggshield.pre-commit with fake op and ggshield on PATH: a rate-limited op read
# blocks the commit with a specific message, other failures keep the generic one, op's raw
# stderr is not echoed, and on success only ggshield sees the key (never the service token).
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
hook="$root/git/hooks/ggshield.pre-commit"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/ggshield-hook-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 TMPDIR="$tmp"
unset GITGUARDIAN_PERSONAL_OP_REF GITGUARDIAN_PERSONAL_REMOTES GITGUARDIAN_API_KEY
mkdir -p "$HOME" "$tmp/bin" "$tmp/scratch"

# Fake op: behaviour is picked by FAKE_OP_MODE. Fake ggshield records what it was given.
cat > "$tmp/bin/op" <<FAKE
#!/bin/sh
case "\${FAKE_OP_MODE:-}" in
	ok) printf 'fake-gg-key' ;;
	ratelimit) echo '[ERROR] 2026/11/11 10:00:00 Too many requests. Your client has been rate-limited. Try again in 42 seconds.' >&2; exit 1 ;;
	ratelimit-nowhen) echo '[ERROR] rate limit exceeded SECRET-STDERR-DETAIL' >&2; exit 1 ;;
	*) echo '[ERROR] item not found SECRET-STDERR-DETAIL' >&2; exit 1 ;;
esac
FAKE
cat > "$tmp/bin/ggshield" <<FAKE
#!/bin/sh
{ echo "args=\$*"; echo "key=\${GITGUARDIAN_API_KEY:-}"; echo "token=\${OP_SERVICE_ACCOUNT_TOKEN:-unset}"; } > "$tmp/ggshield.log"
exit 0
FAKE
chmod +x "$tmp/bin/op" "$tmp/bin/ggshield"
export PATH="$tmp/bin:$PATH" OP_SERVICE_ACCOUNT_TOKEN=fake-service-token

repo="$tmp/repo"
git init -q --template= "$repo"
git -C "$repo" remote add origin git@github.com:hacker1db/example.git

failures=0
expect() { # name command...: the command must succeed
	name=$1; shift
	if "$@"; then echo "ok   $name"; else echo "FAIL $name"; failures=$((failures + 1)); fi
}
refute() { # name command...: the command must fail
	name=$1; shift
	if "$@"; then echo "FAIL $name"; failures=$((failures + 1)); else echo "ok   $name"; fi
}
run() { (cd "$repo" && FAKE_OP_MODE=$1 sh "$hook" >"$tmp/out" 2>&1); }
has() { grep -qF -- "$1" "$tmp/out"; }

refute "rate limit blocks the commit" run ratelimit
expect "rate limit message" has "service account is rate-limited"
expect "rate limit retry time" has "Try again in 42 seconds"
refute "rate limit avoids generic message" has "Could not read the GitGuardian key"
refute "rate limit hides raw op stderr" has "[ERROR]"

refute "rate limit (no time) blocks" run ratelimit-nowhen
expect "rate limit (no time) message" has "service account is rate-limited"
refute "rate limit (no time) omits retry" has "1Password says"
refute "rate limit (no time) hides raw stderr" has "SECRET-STDERR-DETAIL"

refute "other op failure blocks" run notfound
expect "other op failure message" has "Could not read the GitGuardian key from 1Password."
refute "other op failure hides raw stderr" has "SECRET-STDERR-DETAIL"

rm -f "$tmp/ggshield.log"
expect "successful read runs ggshield" run ok
expect "ggshield gets the key" grep -qx 'key=fake-gg-key' "$tmp/ggshield.log" 2>/dev/null
expect "ggshield does not get the token" grep -qx 'token=unset' "$tmp/ggshield.log" 2>/dev/null

leftover=$(find "$tmp" -maxdepth 1 -name 'ggshield-op.*' | wc -l | tr -d ' ')
expect "temp stderr files removed" [ "$leftover" = 0 ]

[ "$failures" -eq 0 ] && echo "All ggshield hook checks passed." || echo "$failures check(s) failed."
[ "$failures" -eq 0 ]
