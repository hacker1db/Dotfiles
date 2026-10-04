#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin" "$fixture/home/.claude" "$fixture/home/.config/claude-code"
export HOME="$fixture/home" PATH="$fixture/bin:$PATH" CAPTURE="$fixture"
printf '%s\n' '{"statusLine":{"command":"unchanged"}}' > "$HOME/.claude/settings.json"
printf '%s\n' 'foundry' > "$HOME/.config/claude-code/backend"
printf '%s\n' '{"env":{"ANTHROPIC_AUTH_TOKEN":"bad","AZURE_CLIENT_SECRET":"bad","CUSTOM_SETTING":"kept"},"autoMode":{"enabled":true}}' > "$HOME/.config/claude-code/automode.json"
cat > "$fixture/bin/claude" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == --settings ]]
settings="$2"
shift 2
[[ -z "${ANTHROPIC_API_KEY:-}" && -z "${ANTHROPIC_AUTH_TOKEN:-}" && -z "${AZURE_CLIENT_SECRET:-}" ]]
cp "$settings" "$CAPTURE/$1.json"
printf '%s\n' "$settings" > "$CAPTURE/$1.path"
printf '%s\n' "$@" > "$CAPTURE/$1.args"
sleep 0.2
exit "${STUB_EXIT:-0}"
STUB
cat > "$fixture/bin/az" <<'STUB'
#!/usr/bin/env bash
if [[ "$1 $2" == 'account show' ]]; then
    exit "${AZ_LOGIN_EXIT:-0}"
fi
printf '%s\n' "${AZ_RESOURCES:-[\"only-resource\"]}"
STUB
chmod +x "$fixture/bin/claude" "$fixture/bin/az"
before="$(shasum "$HOME/.claude/settings.json" "$HOME/.config/claude-code/backend")"
export ANTHROPIC_API_KEY=bad ANTHROPIC_AUTH_TOKEN=bad AZURE_CLIENT_SECRET=bad CLAUDE_CODE_USE_VERTEX=1
"$root/bin/claude-subscription" subscription 'prompt with spaces' &
pid=$!
ANTHROPIC_DEFAULT_OPUS_MODEL=custom-opus "$root/bin/claude-foundry" foundry --continue
wait "$pid"
jq -e '.env.CLAUDE_CODE_USE_FOUNDRY == "0" and .env.CLAUDE_CODE_USE_VERTEX == "0" and .env.ANTHROPIC_DEFAULT_OPUS_MODEL == "" and .env.ANTHROPIC_AUTH_TOKEN == "" and .env.AZURE_CLIENT_SECRET == "" and .env.CUSTOM_SETTING == "kept" and .apiKeyHelper == "" and (has("statusLine") | not)' "$fixture/subscription.json" >/dev/null
jq -e '.env.CLAUDE_CODE_USE_FOUNDRY == "1" and .env.ANTHROPIC_FOUNDRY_RESOURCE == "only-resource" and .env.ANTHROPIC_DEFAULT_OPUS_MODEL == "custom-opus" and .env.ANTHROPIC_DEFAULT_SONNET_MODEL == "claude-sonnet-4-6" and .env.ANTHROPIC_FOUNDRY_API_KEY == "" and .env.ANTHROPIC_FOUNDRY_AUTH_TOKEN == ""' "$fixture/foundry.json" >/dev/null
[[ "$(cat "$fixture/subscription.path")" != "$(cat "$fixture/foundry.path")" ]]
[[ ! -e "$(cat "$fixture/subscription.path")" && ! -e "$(cat "$fixture/foundry.path")" ]]
[[ "$(sed -n '2p' "$fixture/subscription.args")" == 'prompt with spaces' ]]
[[ "$before" == "$(shasum "$HOME/.claude/settings.json" "$HOME/.config/claude-code/backend")" ]]
if AZ_RESOURCES='["one","two"]' "$root/bin/claude-foundry" ambiguous 2>/dev/null; then exit 1; fi
if AZ_RESOURCES='[]' "$root/bin/claude-foundry" missing 2>/dev/null; then exit 1; fi
if AZ_LOGIN_EXIT=1 "$root/bin/claude-foundry" login 2>/dev/null; then exit 1; fi
if "$root/bin/claude-subscription" --settings '{}' 2>/dev/null; then exit 1; fi
ANTHROPIC_FOUNDRY_BASE_URL=https://explicit.example/anthropic AZ_RESOURCES='[]' "$root/bin/claude-foundry" explicit
jq -e '.env.ANTHROPIC_FOUNDRY_BASE_URL == "https://explicit.example/anthropic"' "$fixture/explicit.json" >/dev/null
code=0
STUB_EXIT=23 "$root/bin/claude-subscription" failure || code=$?
[[ "$code" == 23 && ! -e "$(cat "$fixture/failure.path")" ]]
printf '%s\n' 'Claude session tests passed.'
