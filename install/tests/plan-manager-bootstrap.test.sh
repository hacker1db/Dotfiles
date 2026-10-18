#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PLAN_REPOSITORY="${PLAN_MANAGER_TEST_REPO_DIR:-$HOME/Developer/plan-manager}"
FIXTURE="$(mktemp -d /tmp/plan-manager-installer-test.XXXXXX)"
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
assert_contains "$ROOT/zsh/zshrc.symlink" 'export PATH="$HOME/.local/bin:$PATH"'
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

fake_worktree="$FIXTURE/fake-worktree"
mkdir -p "$fake_worktree/bin"
printf '{}\n' > "$fake_worktree/package.json"
printf 'lockfileVersion: 9.0\n' > "$fake_worktree/pnpm-lock.yaml"
cat > "$fake_worktree/bin/plan" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "--version" ]; then
    echo "1.2.3"
    exit 0
fi
exit 0
EOF
chmod +x "$fake_worktree/bin/plan"
cat > "$FIXTURE/fake-bin/pnpm" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$FIXTURE/pnpm-arguments"
exit 0
EOF
chmod +x "$FIXTURE/fake-bin/pnpm"
PLAN_WORKTREE="$fake_worktree"
export PLAN_WORKTREE
PATH="$FIXTURE/fake-bin:$PATH" install_plan_cli >/dev/null
[ -L "$PLAN_LINK" ] || fail "validated CLI was not linked"
[ "$(readlink "$PLAN_LINK")" = "$fake_worktree/bin/plan" ] || fail "CLI link target is wrong"
assert_contains "$FIXTURE/pnpm-arguments" "--dir $fake_worktree install --frozen-lockfile"
assert_contains "$FIXTURE/pnpm-arguments" "--dir $fake_worktree build"
PATH="$FIXTURE/fake-bin:$PATH" install_plan_cli >/dev/null
[ "$(find "$LOCAL_BIN" -name 'plan.backup-*' | wc -l | tr -d ' ')" = "0" ] ||
    fail "idempotent CLI linking created a backup"
chmod -x "$fake_worktree/bin/plan"
PATH="$FIXTURE/fake-bin:$PATH" install_plan_cli >/dev/null 2>&1 &&
    fail "non-executable repository CLI was accepted"
[ -L "$PLAN_LINK" ] || fail "invalid repository CLI removed the working link"
chmod +x "$fake_worktree/bin/plan"

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

echo "plan-manager installer tests passed"
