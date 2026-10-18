#!/usr/bin/env bash
# Fixture test for install/claude-profiles.sh in a temporary HOME with stub claude/skillctl.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT
repo="$temp/repo"
home="$temp/home"
stubs="$temp/bin"
log="$temp/calls.log"
mkdir -p "$repo/install" "$home/OneDrive - Fixture/Personal" "$stubs"
rsync -a --exclude .local --exclude skills --exclude plugins "$root/claude" "$repo/"
cp "$root/install/claude-profiles.sh" "$repo/install/"
# Fixture subscription layer so hook scoping is tested independently of the real file's contents.
cat > "$repo/claude/profiles/subscription/settings.json" << 'EOF'
{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "fixture-subscription-hook"}]}]}}
EOF
echo 'export ANTHROPIC_FOUNDRY_RESOURCE=fixture-resource' > "$home/OneDrive - Fixture/Personal/.localrc"
for tool in claude skillctl; do
    cat > "$stubs/$tool" << 'EOF'
#!/usr/bin/env bash
echo "$(basename "$0") ${CLAUDE_CONFIG_DIR##*/} $*" >> "$CALL_LOG"
case "$*" in *--json*) echo '[]' ;; esac
EOF
    chmod +x "$stubs/$tool"
done
mkdir -p "$home/.claude-personal"
echo '{"theme": "unmanaged"}' > "$home/.claude-personal/settings.json"

run() {
    env -i HOME="$home" PATH="$stubs:$(dirname "$(command -v jq)"):/usr/bin:/bin" CALL_LOG="$log" "$@" "$repo/install/claude-profiles.sh" ${args[@]+"${args[@]}"}
}
fail() { echo "FAIL: $*" >&2; exit 1; }
mode_of() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }
setting() { jq -r "$2" "$home/.claude-$1/settings.json"; }

# First install reads the resource from ~/.localrc (not the environment) and creates the link.
args=()
run > "$temp/out1" || fail "first install exited $? $(cat "$temp/out1")"
[ "$(readlink "$home/.localrc")" = "$home/OneDrive - Fixture/Personal/.localrc" ] || fail ".localrc link"
for p in personal subscription foundry; do
    d="$home/.claude-$p"
    [ "$(mode_of "$d")" = 700 ] || fail "$p dir mode"
    [ "$(readlink "$d/settings.json")" = "$repo/claude/.local/profiles/$p.json" ] || fail "$p settings target"
    [ "$(mode_of "$repo/claude/.local/profiles/$p.json")" = 600 ] || fail "$p settings mode"
    [ -d "$d/skills" ] && [ ! -L "$d/skills" ] || fail "$p skills dir"
    for item in CLAUDE.md agents commands output-styles statusline-command.sh; do
        [ "$(readlink "$d/$item")" = "$repo/claude/$item" ] || fail "$p link $item"
    done
    [ "$(readlink "$d/hooks")" = "$repo/claude/profiles/$p/hooks" ] || fail "$p hooks link"
    grep -qx "skillctl .claude-$p sync --global" "$log" || fail "$p skillctl sync"
    [ "$(setting "$p" '.env.CLAUDE_CODE_USE_BEDROCK + .env.CLAUDE_CODE_USE_VERTEX')" = 00 ] || fail "$p bedrock/vertex"
done
[ "$(setting personal '.enabledPlugins["vercel@claude-plugins-official"] and .enabledPlugins["todoist@doist"]')" = true ] || fail "personal plugins"
[ "$(setting subscription '.hooks | tostring | contains("fixture-subscription-hook")')" = true ] || fail "subscription missing its hook"
for p in personal foundry; do
    [ "$(setting "$p" '.hooks // {} | tostring | contains("fixture-subscription-hook")')" = false ] || fail "$p has subscription hook"
done
for p in subscription foundry; do
    [ "$(setting "$p" '.enabledPlugins | has("vercel@claude-plugins-official") or has("todoist@doist")')" = false ] || fail "$p has personal plugins"
done
for p in personal subscription; do
    [ "$(setting "$p" '.env.CLAUDE_CODE_USE_FOUNDRY + .forceLoginMethod')" = 0claudeai ] || fail "$p provider"
done
[ "$(setting foundry '.env.CLAUDE_CODE_USE_FOUNDRY + .env.ANTHROPIC_FOUNDRY_RESOURCE')" = 1fixture-resource ] || fail "foundry provider"
[ "$(setting foundry '.model')" = opus ] || fail "foundry must use Opus for auto mode"
[ "$(setting foundry '.permissions.defaultMode')" = auto ] || fail "foundry auto permission mode"
grep -q 'claude .claude-personal plugin install todoist@doist' "$log" || fail "personal plugin install"
grep -q 'claude .claude-subscription plugin install todoist@doist' "$log" && fail "subscription installed personal plugin"
grep -q 'claude .claude-foundry plugin marketplace add HKUDS/CLI-Anything' "$log" || fail "marketplace add"
backups="$(ls "$home/.claude-personal" | grep -c 'settings.json.backup.')"
[ "$backups" = 1 ] || fail "expected one backup, got $backups"

# Second run is a no-op and --check passes, with ANTHROPIC_FOUNDRY_RESOURCE in env not reported.
snapshot() { cat "$repo"/claude/.local/profiles/*.json; ls -l "$home"/.claude-*; }
before="$(snapshot)"
run ANTHROPIC_FOUNDRY_RESOURCE=fixture-resource > "$temp/out2" || fail "second install $(cat "$temp/out2")"
[ "$(snapshot)" = "$before" ] || fail "second run changed state"
grep -q -E 'Generated|Linked|Backed up' "$temp/out2" && fail "second run reported changes: $(cat "$temp/out2")"
args=(--check)
run ANTHROPIC_FOUNDRY_RESOURCE=fixture-resource > "$temp/out3" || fail "check $(cat "$temp/out3")"
grep -q Inherited "$temp/out3" && fail "resource reported as conflict"

# Dirty environment is reported by name only.
code=0
run ANTHROPIC_API_KEY=dummy-never-print CLAUDE_CODE_USE_BEDROCK=1 > "$temp/out4" || code=$?
[ "$code" = 2 ] || fail "dirty check exit $code"
grep -q 'ANTHROPIC_API_KEY' "$temp/out4" && grep -q CLAUDE_CODE_USE_BEDROCK "$temp/out4" || fail "conflict names"
grep -q dummy-never-print "$temp/out4" && fail "leaked value"

# Stale generated settings fail the check.
echo '{}' > "$repo/claude/.local/profiles/subscription.json"
code=0; run > "$temp/out5" || code=$?
[ "$code" = 2 ] && grep -q 'subscription: generated settings are stale' "$temp/out5" || fail "stale check"
args=(); run > /dev/null || fail "repair run"

# --skip-foundry leaves Foundry untouched; missing resource is incomplete, not fatal.
rm "$home/.claude-foundry/settings.json"
args=(--skip-foundry); run > /dev/null || fail "skip-foundry"
[ ! -e "$home/.claude-foundry/settings.json" ] || fail "skip-foundry wrote foundry"
echo '# no resource' > "$home/OneDrive - Fixture/Personal/.localrc"
args=(); code=0; run > "$temp/out6" || code=$?
[ "$code" = 2 ] && grep -q 'Foundry skipped' "$temp/out6" || fail "missing resource"

# Credentials in a layer are rejected before anything is written.
echo 'export ANTHROPIC_FOUNDRY_RESOURCE=fixture-resource' > "$home/OneDrive - Fixture/Personal/.localrc"
before="$(snapshot)"
jq '.apiKeyHelper = "helper"' "$repo/claude/profiles/personal/settings.json" > "$temp/p.json" && mv "$temp/p.json" "$repo/claude/profiles/personal/settings.json"
code=0; run > /dev/null 2>&1 || code=$?
[ "$code" = 1 ] || fail "credential rejection exit $code"
[ "$(snapshot)" = "$before" ] || fail "credential rejection changed state"

# Unexpected ~/.localrc and OneDrive layouts fail loudly.
rm "$home/.localrc"; touch "$home/.localrc"
code=0; run > /dev/null 2>&1 || code=$?; [ "$code" = 1 ] || fail "regular .localrc accepted"
rm "$home/.localrc"; mkdir "$home/OneDrive - Second"
code=0; run > /dev/null 2>&1 || code=$?; [ "$code" = 1 ] || fail "two OneDrive dirs accepted"

echo "claude-profiles tests passed"
