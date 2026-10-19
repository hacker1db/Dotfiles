#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PLAN_REPOSITORY="${PLAN_MANAGER_TEST_REPO_DIR:-$HOME/Developer/plan-manager}"
FIXTURE="$(mktemp -d /tmp/plan-manager-installer-test.XXXXXX)"
FIXTURE="$(cd "$FIXTURE" && pwd -P)"
trap 'rm -rf "$FIXTURE"' EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_contains() {
    local file="$1"
    local expected="$2"
    grep -qF -- "$expected" "$file" || fail "$file does not contain $expected"
}

assert_contains "$ROOT/install/link.sh" 'source "$DOTFILES/install/plan-manager-bootstrap.sh"'
assert_contains "$ROOT/install/link.sh" 'bootstrap_plan_repo && install_plan_cli'
assert_contains "$ROOT/install/link.sh" 'install_plan_launch_agent'
assert_contains "$ROOT/install/link.sh" 'initialize_plan_library'
assert_contains "$ROOT/install/link.sh" 'check_plan_manager'
assert_contains "$ROOT/zsh/zshrc.symlink" 'path=("$HOME/.local/bin" $path)'
if grep -qE '/Users/[^<]' "$ROOT/launchd/com.plan-manager.serve.plist.template"; then
    fail "LaunchAgent template contains a machine-specific user path"
fi
if grep -qE '/opt/homebrew|/usr/local' "$ROOT/launchd/com.plan-manager.serve.plist.template"; then
    fail "LaunchAgent template assumes a package-manager prefix"
fi

HOME="$FIXTURE/home"
mkdir -p "$HOME/.codex"
export HOME
export PLAN_MANAGER_REPO_DIR="$PLAN_REPOSITORY"
export PLAN_MANAGER_SKIP_LAUNCHCTL=1
source "$ROOT/install/plan-manager-bootstrap.sh"

resolved="$(resolve_worktree "$PLAN_MANAGER_REPO_DIR")"
if [ -d "$PLAN_REPOSITORY/.bare" ]; then
    expected_resolved="$PLAN_REPOSITORY/main"
else
    expected_resolved="$PLAN_REPOSITORY"
fi
[ "$resolved" = "$expected_resolved" ] ||
    fail "bare-worktree resolution returned $resolved"
PLAN_MANAGER_TEST_BIN="$resolved/bin/plan" \
    node "$ROOT/install/tests/plan-manager-harness-contracts.test.mjs"

saved_home="$HOME"
HOME="$FIXTURE/failing-policy-home"
mkdir -p "$HOME"
printf 'conflict\n' > "$HOME/.copilot"
install_plan_instruction_links >/dev/null 2>&1 &&
    fail "a failed harness-policy link was reported as success"
HOME="$saved_home"
export HOME

PLAN_MANAGER_WORKTREE="$FIXTURE" resolve_worktree "$PLAN_MANAGER_REPO_DIR" >/dev/null 2>&1 &&
    fail "invalid explicit worktree was accepted"
unset PLAN_MANAGER_WORKTREE

PLAN_MANAGER_WORKTREE="$resolved"
explicit="$(resolve_worktree "$PLAN_MANAGER_REPO_DIR")"
[ "$explicit" = "$resolved" ] || fail "valid explicit worktree was rejected"
unset PLAN_MANAGER_WORKTREE

validate_origin "$resolved" "git@github.com:example/plan-manager.git" >/dev/null 2>&1 &&
    fail "missing expected origin was accepted"

mkdir -p "$FIXTURE/fake-ssh"
cat > "$FIXTURE/fake-ssh/ssh" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "-G" ] && [ "${2:-}" = "github-alias" ]; then
    echo "hostname ssh.github.com"
    exit 0
fi
if [ "${1:-}" = "-G" ] && [ "${2:-}" = "github.com" ]; then
    echo "hostname ssh.github.com"
    exit 0
fi
[ "${1:-}" = "-G" ] && echo "hostname ${2:-}"
exit 0
EOF
chmod +x "$FIXTURE/fake-ssh/ssh"
alias_repo="$FIXTURE/alias-origin"
git init -q "$alias_repo"
git -C "$alias_repo" remote add origin "git@github-alias:hacker1db/plan-manager.git"
PATH="$FIXTURE/fake-ssh:$PATH" validate_origin "$alias_repo" "git@github.com:hacker1db/plan-manager.git" >/dev/null 2>&1 ||
    fail "SSH host alias for the expected origin was rejected"
PATH="$FIXTURE/fake-ssh:$PATH" validate_origin "$alias_repo" "https://github.com/hacker1db/plan-manager.git" >/dev/null 2>&1 ||
    fail "SSH host alias was not equivalent to the HTTPS origin"
PATH="$FIXTURE/fake-ssh:$PATH" validate_origin "$alias_repo" "git@github.com:example/plan-manager.git" >/dev/null 2>&1 &&
    fail "SSH host alias for a different owner was accepted"
git -C "$alias_repo" remote set-url origin "git@gitlab-alias:hacker1db/plan-manager.git"
PATH="$FIXTURE/fake-ssh:$PATH" validate_origin "$alias_repo" "git@github.com:hacker1db/plan-manager.git" >/dev/null 2>&1 &&
    fail "SSH host alias for a different host was accepted"
git -C "$alias_repo" remote set-url origin "git@unresolved-alias:hacker1db/plan-manager.git"
git -C "$alias_repo" config url."git@unresolved-alias:hacker1db/".insteadOf "git@github.com:hacker1db/"
PATH="$FIXTURE/fake-ssh:$PATH" validate_origin "$alias_repo" "git@github.com:hacker1db/plan-manager.git" >/dev/null 2>&1 ||
    fail "insteadOf-rewritten expected origin was rejected"
PATH="$FIXTURE/fake-ssh:$PATH" validate_origin "$alias_repo" "git@github.com:example/plan-manager.git" >/dev/null 2>&1 &&
    fail "insteadOf rewrite accepted a different owner"

mkdir -p "$FIXTURE/fake-bin"
cat > "$FIXTURE/fake-bin/gh" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$FIXTURE/fake-bin/gh"
cat > "$FIXTURE/fake-bin/git" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$FIXTURE/git-arguments"
if [ "\${3:-}" = "status" ]; then
    exit 0
fi
exit 99
EOF
chmod +x "$FIXTURE/fake-bin/git"
mkdir -p "$FIXTURE/clean-no-origin"
PATH="$FIXTURE/fake-bin:$PATH" update_clean_worktree "$FIXTURE/clean-no-origin" "" >/dev/null ||
    fail "clean checkout without a configured origin was rejected"
[ "$(wc -l < "$FIXTURE/git-arguments" | tr -d ' ')" = "1" ] ||
    fail "clean checkout without an origin attempted another Git operation"
assert_contains "$FIXTURE/git-arguments" "-C $FIXTURE/clean-no-origin status --porcelain --untracked-files=normal"

original_repo_dir="$PLAN_REPO_DIR"
PLAN_REPO_DIR="$FIXTURE/missing-repository"
PATH="$FIXTURE/fake-bin:$PATH" bootstrap_plan_repo >/dev/null 2>&1 &&
    fail "missing repository without a URL was accepted"
[ ! -e "$PLAN_REPO_DIR" ] || fail "missing-URL bootstrap created a partial target"
PLAN_REPO_DIR="$FIXTURE/conflicting-target"
printf 'conflict\n' > "$PLAN_REPO_DIR"
bootstrap_plan_repo >/dev/null 2>&1 && fail "non-directory repository target was accepted"
PLAN_REPO_DIR="$original_repo_dir"

rm "$FIXTURE/fake-bin/git"
fake_worktree="$FIXTURE/fake worktree"
mkdir -p "$fake_worktree/cli/cmd/plan"
printf 'module github.com/hacker1db/plan-manager/cli\n\ngo 1.26.2\n' > "$fake_worktree/cli/go.mod"
printf 'package main\n' > "$fake_worktree/cli/cmd/plan/main.go"
cat > "$FIXTURE/fake-bin/go" <<'EOF'
#!/bin/bash
if [ "$1" = install ]; then
    printf '%s|%s|%s|%s|%s\n' "$PWD" "$GOBIN" "$GOWORK" "$GOFLAGS" "$*" >> "$GO_TEST_LOG"
    [ "${GO_TEST_FAILURE:-}" != build ] || exit 1
    cat > "$GOBIN/plan" <<'BIN'
#!/bin/sh
case "$*" in
    --version) [ "${GO_TEST_FAILURE:-}" != version ] || exit 1; echo 'plan version 1.2.3' ;;
    'completion zsh') [ "${GO_TEST_FAILURE:-}" != completion ] || exit 1; echo 'compdef _plan plan' ;;
esac
BIN
    chmod +x "$GOBIN/plan"
    exit 0
fi
if [ "$1 $2" = 'version -m' ]; then
    echo 'path github.com/hacker1db/plan-manager/cli/cmd/plan'
    [ "${GO_TEST_FAILURE:-}" != identity ] || exit 1
    echo 'mod github.com/hacker1db/plan-manager/cli (devel)'
    exit 0
fi
exit 99
EOF
chmod +x "$FIXTURE/fake-bin/go"
export GO_TEST_LOG="$FIXTURE/go-arguments"
PLAN_WORKTREE="$fake_worktree"
export PLAN_WORKTREE
PATH="$FIXTURE/fake-bin:$PATH" GOBIN="$FIXTURE/ambient-bin" install_plan_cli >/dev/null
[ -L "$PLAN_LINK" ] || fail "validated CLI was not linked"
[ "$(readlink "$PLAN_LINK")" = "$HOME/.local/lib/plan-manager/plan" ] || fail "CLI link target is wrong"
assert_contains "$GO_TEST_LOG" "$fake_worktree/cli|$HOME/.local/lib/plan-manager/.stage."
assert_contains "$GO_TEST_LOG" '|off||install -mod=readonly ./cmd/plan'
[ ! -e "$FIXTURE/ambient-bin" ] || fail "ambient GOBIN was used"
PATH="$FIXTURE/fake-bin:$PATH" install_plan_cli >/dev/null
[ "$PLAN_CLI_CHANGED" = 0 ] || fail "identical binary was reported changed"
[ "$(find "$LOCAL_BIN" -name 'plan.backup-*' | wc -l | tr -d ' ')" = 0 ] || fail "reinstall backed up unchanged link"

rm "$PLAN_LINK"
ln -s "$fake_worktree/legacy-plan" "$PLAN_LINK"
printf '#!/bin/sh\necho legacy\n' > "$fake_worktree/legacy-plan"
chmod +x "$fake_worktree/legacy-plan"
PATH="$FIXTURE/fake-bin:$PATH" install_plan_cli >/dev/null
[ "$(readlink "$PLAN_LINK")" = "$HOME/.local/lib/plan-manager/plan" ] || fail "TypeScript migration failed"
legacy_backup="$(find "$LOCAL_BIN" -name 'plan.backup-*')"
[ "$("$legacy_backup")" = legacy ] || fail "legacy backup is unusable"

previous="$(shasum -a 256 "$PLAN_LINK")"
for failure in build identity version completion; do
    PATH="$FIXTURE/fake-bin:$PATH" GO_TEST_FAILURE="$failure" install_plan_cli >/dev/null 2>&1 && fail "$failure failure accepted"
    [ "$(shasum -a 256 "$PLAN_LINK")" = "$previous" ] || fail "$failure replaced the previous binary"
    [ "$("$PLAN_LINK" --version)" = 'plan version 1.2.3' ] || fail "$failure broke previous command"
done
mv "$fake_worktree/cli/cmd/plan/main.go" "$fake_worktree/main.go"
PATH="$FIXTURE/fake-bin:$PATH" install_plan_cli >/dev/null 2>&1 && fail "missing Go source accepted"
[ "$(shasum -a 256 "$PLAN_LINK")" = "$previous" ] || fail "missing source changed previous command"
mv "$fake_worktree/main.go" "$fake_worktree/cli/cmd/plan/main.go"
mkdir -p "$FIXTURE/no-go"
ln -s /usr/bin/dirname "$FIXTURE/no-go/dirname"
PATH="$FIXTURE/no-go" install_plan_cli >/dev/null 2>&1 && fail "missing Go accepted"
[ "$(shasum -a 256 "$PLAN_LINK")" = "$previous" ] || fail "missing Go changed previous command"

normal="$FIXTURE/normal clone"
git init -q "$normal"
printf 'fixture\n' > "$normal/README"
git -C "$normal" add README
git -C "$normal" -c user.name=Fixture -c user.email=fixture@example.test -c commit.gpgsign=false commit -qm fixture
[ "$(resolve_worktree "$normal")" = "$normal" ] || fail "normal clone resolution failed"
git -C "$normal" branch -M main
bare="$FIXTURE/bare repo"
mkdir -p "$bare"
git clone --bare -q "$normal" "$bare/.bare"
git --git-dir="$bare/.bare" worktree add -q "$bare/main" main
git --git-dir="$bare/.bare" worktree add -qb explicit "$bare/custom worktree"
[ "$(resolve_worktree "$bare")" = "$bare/main" ] || fail "fixture bare resolution failed"
[ "$(PLAN_MANAGER_WORKTREE="$bare/custom worktree" resolve_worktree "$bare")" = "$bare/custom worktree" ] || fail "explicit bare override failed"
PLAN_MANAGER_WORKTREE="$normal" resolve_worktree "$bare" >/dev/null 2>&1 && fail "unrelated override accepted"
for selected in "$normal" "$bare/main" "$bare/custom worktree"; do
    cp -R "$fake_worktree/cli" "$selected/cli"
    PLAN_WORKTREE="$selected" PATH="$FIXTURE/fake-bin:$PATH" install_plan_cli >/dev/null
    assert_contains "$GO_TEST_LOG" "$selected/cli|"
done

cat > "$HOME/.codex/config.toml" <<EOF
model = "existing"
# $HOME/notes/SecondBrain/4.Resources/plans in a comment must not count

[sandbox_workspace_write]
writable_roots = [
  "/tmp/existing", # keep this root
]

[unrelated]
enabled = true
EOF

node "$ROOT/install/reconcile-codex-config.mjs" \
    "$HOME/.codex/config.toml" "$HOME/notes/SecondBrain/4.Resources/plans" >/dev/null
assert_contains "$HOME/.codex/config.toml" 'model = "existing"'
assert_contains "$HOME/.codex/config.toml" '"/tmp/existing", # keep this root'
assert_contains "$HOME/.codex/config.toml" "\"$HOME/notes/SecondBrain/4.Resources/plans\""
assert_contains "$HOME/.codex/config.toml" 'enabled = true'

before="$(shasum -a 256 "$HOME/.codex/config.toml")"
node "$ROOT/install/reconcile-codex-config.mjs" \
    "$HOME/.codex/config.toml" "$HOME/notes/SecondBrain/4.Resources/plans" >/dev/null
after="$(shasum -a 256 "$HOME/.codex/config.toml")"
[ "$before" = "$after" ] || fail "second Codex reconciliation changed the file"
[ "$(find "$HOME/.codex" -name 'config.toml.backup-*' | wc -l | tr -d ' ')" = "1" ] ||
    fail "Codex reconciliation did not create exactly one backup"

mkdir -p "$FIXTURE/new-codex"
node "$ROOT/install/reconcile-codex-config.mjs" \
    "$FIXTURE/new-codex/config.toml" "$HOME/notes/SecondBrain/4.Resources/plans" >/dev/null
assert_contains "$FIXTURE/new-codex/config.toml" '[sandbox_workspace_write]'
assert_contains "$FIXTURE/new-codex/config.toml" "\"$HOME/notes/SecondBrain/4.Resources/plans\""

cat > "$FIXTURE/duplicate.toml" <<'EOF'
[sandbox_workspace_write]
writable_roots = []
writable_roots = []
EOF
duplicate_before="$(shasum -a 256 "$FIXTURE/duplicate.toml")"
node "$ROOT/install/reconcile-codex-config.mjs" \
    "$FIXTURE/duplicate.toml" "$HOME/notes/SecondBrain/4.Resources/plans" >/dev/null 2>&1 &&
    fail "duplicate writable_roots was accepted"
duplicate_after="$(shasum -a 256 "$FIXTURE/duplicate.toml")"
[ "$duplicate_before" = "$duplicate_after" ] || fail "invalid TOML was modified"

managed_source="$FIXTURE/managed.md"
managed_dest="$HOME/.codex/AGENTS.md"
printf 'managed\n' > "$managed_source"
printf 'unmanaged\n' > "$managed_dest"
link_managed_file "$managed_source" "$managed_dest" "test instructions" >/dev/null
[ -L "$managed_dest" ] || fail "managed instruction was not linked"
[ "$(find "$HOME/.codex" -name 'AGENTS.md.backup-*' | wc -l | tr -d ' ')" = "1" ] ||
    fail "unmanaged instruction was not backed up"
link_managed_file "$managed_source" "$managed_dest" "test instructions" >/dev/null
[ "$(find "$HOME/.codex" -name 'AGENTS.md.backup-*' | wc -l | tr -d ' ')" = "1" ] ||
    fail "idempotent instruction linking created another backup"

instruction_home="$FIXTURE/instruction-home"
bash "$ROOT/install/agent-instructions.sh" "$instruction_home" >/dev/null
original_home="$HOME"
HOME="$instruction_home"
install_plan_instruction_links >/dev/null
bash "$ROOT/install/agent-instructions.sh" "$HOME" >/dev/null
[ "$HOME/.copilot/copilot-instructions.md" -ef "$ROOT/global/AGENTS.md" ] ||
    fail "Copilot installers selected different instructions"
[ "$(find "$HOME/.copilot" -name 'copilot-instructions.md.backup.*' | wc -l | tr -d ' ')" = "0" ] ||
    fail "Copilot installers replaced each other's links"
HOME="$original_home"

mkdir -p "$HOME/.config/opencode/command"
printf 'preserve\n' > "$HOME/.config/opencode/custom-state"
install_plan_instruction_links >/dev/null
[ -f "$HOME/.config/opencode/custom-state" ] || fail "unmanaged OpenCode state was removed"
[ -L "$HOME/.config/opencode/AGENTS.md" ] || fail "OpenCode global instructions were not linked"
[ -L "$HOME/.config/opencode/command/plans.md" ] || fail "OpenCode plans command was not linked"
[ -L "$HOME/.copilot/copilot-instructions.md" ] || fail "Copilot global instructions were not linked"
[ -L "$HOME/.codex/AGENTS.md" ] || fail "Codex global instructions were not linked"

PLAN_WORKTREE="$resolved"
export PLAN_WORKTREE
PLAN_LINK="$HOME/.local/bin/plan"
export PLAN_LINK
mkdir -p "$(dirname "$PLAN_LINK")"
install_plan_launch_agent >/dev/null
plist="$HOME/Library/LaunchAgents/com.plan-manager.serve.plist"
plutil -lint "$plist" >/dev/null
assert_contains "$plist" "$PLAN_LINK"
assert_contains "$plist" "$PLAN_WORKTREE"
assert_contains "$plist" "$HOME/notes/SecondBrain/4.Resources/plans"
plist_before="$(shasum -a 256 "$plist")"
install_plan_launch_agent >/dev/null
plist_after="$(shasum -a 256 "$plist")"
[ "$plist_before" = "$plist_after" ] || fail "second LaunchAgent render changed the file"

cat > "$FIXTURE/fake-bin/launchctl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$LAUNCH_TEST_LOG"
case "$1" in
    print) [ -f "$LAUNCH_TEST_STATE" ] ;;
    bootout) rm "$LAUNCH_TEST_STATE" ;;
    bootstrap) touch "$LAUNCH_TEST_STATE" ;;
    *) exit 99 ;;
esac
EOF
chmod +x "$FIXTURE/fake-bin/launchctl"
export LAUNCH_TEST_LOG="$FIXTURE/launchctl-arguments"
export LAUNCH_TEST_STATE="$FIXTURE/launchctl-loaded"
PLAN_MANAGER_SKIP_LAUNCHCTL=0 PATH="$FIXTURE/fake-bin:$PATH" install_plan_launch_agent >/dev/null
PLAN_MANAGER_SKIP_LAUNCHCTL=0 PATH="$FIXTURE/fake-bin:$PATH" install_plan_launch_agent >/dev/null
[ "$(grep -c '^bootstrap ' "$LAUNCH_TEST_LOG")" = 1 ] || fail "unchanged agent was reloaded"
printf '\n# changed binary\n' >> "$HOME/.local/lib/plan-manager/plan"
PLAN_MANAGER_SKIP_LAUNCHCTL=0 PATH="$FIXTURE/fake-bin:$PATH" install_plan_launch_agent >/dev/null
[ "$(grep -c '^bootout ' "$LAUNCH_TEST_LOG")" = 1 ] || fail "binary-only change did not unload service"
[ "$(grep -c '^bootstrap ' "$LAUNCH_TEST_LOG")" = 2 ] || fail "binary-only change did not reload service"

cat > "$FIXTURE/fake-bin/lsof" <<'EOF'
#!/bin/sh
case "$*" in
    *-iTCP:*) echo 123 ;;
    *) printf 'p123\nn%s\n' "$LSOF_TEST_EXEC" ;;
esac
EOF
chmod +x "$FIXTURE/fake-bin/lsof"
LSOF_TEST_EXEC="$HOME/.local/lib/plan-manager/plan" PATH="$FIXTURE/fake-bin:$PATH" verify_plan_service >/dev/null || fail "managed service executable rejected"
LSOF_TEST_EXEC='/usr/bin/node' PATH="$FIXTURE/fake-bin:$PATH" verify_plan_service >/dev/null 2>&1 && fail "legacy service executable accepted"
cat > "$FIXTURE/fake-bin/zsh" <<'EOF'
#!/bin/sh
case "$*" in
    *'whence -w'*) echo "plan: ${ZSH_TEST_KIND:-command}" ;;
    *) echo "$PLAN_LINK" ;;
esac
EOF
chmod +x "$FIXTURE/fake-bin/zsh"
export PLAN_LINK
PATH="$FIXTURE/fake-bin:$PATH" diagnose_plan_command >/dev/null || fail "managed command diagnostic failed"
for kind in alias function; do
    ZSH_TEST_KIND="$kind" PATH="$FIXTURE/fake-bin:$PATH" diagnose_plan_command >/dev/null 2>&1 && fail "$kind shadow was not diagnosed"
done

echo "plan-manager installer tests passed"
