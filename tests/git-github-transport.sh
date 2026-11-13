#!/bin/sh
# Checks the GitHub transport rules in git/gitconfig.symlink: fetches use HTTPS, pushes use SSH,
# and only GitHub hosts get the gh credential helper. Hermetic: a temp HOME, no system config,
# a fake gh first on PATH, and no network access (only URL resolution and `git credential`).
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/git-transport-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home" GIT_CONFIG_GLOBAL="$root/git/gitconfig.symlink" GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false SSH_ASKPASS=/bin/false
unset GIT_DIR GIT_WORK_TREE GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
mkdir -p "$HOME" "$tmp/bin"

# The fake gh records each call and answers `auth git-credential get` with dummy values.
cat > "$tmp/bin/gh" <<FAKE
#!/bin/sh
printf '%s\n' "\$*" >> "$tmp/gh.log"
cat >/dev/null
[ "\$*" = "auth git-credential get" ] && printf 'username=fake-user\npassword=fake-token\n'
exit 0
FAKE
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"

failures=0
check() { # name expected actual
	if [ "$2" = "$3" ]; then
		echo "ok   $1"
	else
		echo "FAIL $1: expected '$2', got '$3'"
		failures=$((failures + 1))
	fi
}

repo="$tmp/repo"
git init -q --template= "$repo"

remote() { # stored-url expected-fetch expected-push
	git -C "$repo" remote remove origin 2>/dev/null
	git -C "$repo" remote add origin "$1"
	check "fetch $1" "$2" "$(git -C "$repo" remote get-url origin)"
	check "push  $1" "$3" "$(git -C "$repo" remote get-url --push origin)"
}

remote git@github.com:o/r.git https://github.com/o/r.git git@github.com:o/r.git
remote ssh://git@github.com/o/r.git https://github.com/o/r.git git@github.com:o/r.git
remote https://github.com/o/r.git https://github.com/o/r.git git@github.com:o/r.git
remote http://github.com/o/r.git https://github.com/o/r.git git@github.com:o/r.git
remote git://github.com/o/r.git https://github.com/o/r.git git@github.com:o/r.git
remote git@gitlab.com:o/r.git git@gitlab.com:o/r.git git@gitlab.com:o/r.git
remote https://example.com/o/r.git https://example.com/o/r.git https://example.com/o/r.git

# An explicit pushurl skips pushInsteadOf, so insteadOf still turns it into HTTPS.
git -C "$repo" remote set-url origin git@github.com:o/r.git
git -C "$repo" config remote.origin.pushurl https://github.com/o/r.git
check "explicit pushurl https" https://github.com/o/r.git "$(git -C "$repo" remote get-url --push origin)"
git -C "$repo" config remote.origin.pushurl git@github.com:o/r.git
check "explicit pushurl ssh" https://github.com/o/r.git "$(git -C "$repo" remote get-url --push origin)"

# Credential helper: gh answers for GitHub hosts and is never asked about other hosts.
fill() { printf 'protocol=https\nhost=%s\n\n' "$1" | git -C "$repo" credential fill 2>/dev/null; }

: > "$tmp/gh.log"
out=$(fill github.com)
check "github.com uses gh" "auth git-credential get" "$(cat "$tmp/gh.log")"
check "github.com password from gh" "password=fake-token" "$(printf '%s\n' "$out" | grep '^password=')"

: > "$tmp/gh.log"
fill gist.github.com >/dev/null
check "gist.github.com uses gh" "auth git-credential get" "$(cat "$tmp/gh.log")"

: > "$tmp/gh.log"
if fill example.com >/dev/null; then status=filled; else status=failed; fi
check "example.com has no helper" failed "$status"
check "example.com does not call gh" "" "$(cat "$tmp/gh.log")"

: > "$tmp/gh.log"
fill github.com.evil.example >/dev/null
check "lookalike host does not call gh" "" "$(cat "$tmp/gh.log")"

[ "$failures" -eq 0 ] && echo "All git transport checks passed." || echo "$failures check(s) failed."
[ "$failures" -eq 0 ]
