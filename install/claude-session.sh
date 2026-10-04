#!/usr/bin/env bash
set -euo pipefail

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

backend="${1:?Expected anthropic or foundry}"
shift
case "$backend" in
    anthropic|foundry) ;;
    *) fail "Unknown Claude backend: $backend" ;;
esac
for arg in "$@"; do
    case "$arg" in
        --settings|--settings=*) fail "Use ordinary Claude arguments; --settings is managed by this launcher." ;;
    esac
done
command -v jq >/dev/null || fail "jq is required."
command -v claude >/dev/null || fail "Claude Code is required."
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
resource="${ANTHROPIC_FOUNDRY_RESOURCE:-}"
endpoint="${ANTHROPIC_FOUNDRY_BASE_URL:-}"
opus="${ANTHROPIC_DEFAULT_OPUS_MODEL:-}"
sonnet="${ANTHROPIC_DEFAULT_SONNET_MODEL:-}"
haiku="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}"
if [[ "$backend" == foundry ]]; then
    command -v az >/dev/null || fail "Azure CLI is required. Run az login first."
    az account show --output none || fail "Azure CLI login is unavailable. Run az login."
    if [[ -z "$resource" && -z "$endpoint" ]]; then
        resources="$(az cognitiveservices account list --query "[?kind=='AIServices'].name" -o json)" || fail "Foundry discovery failed. Set ANTHROPIC_FOUNDRY_RESOURCE or ANTHROPIC_FOUNDRY_BASE_URL."
        [[ "$(jq 'length' <<< "$resources")" == 1 ]] || fail "Foundry discovery needs exactly one resource. Set ANTHROPIC_FOUNDRY_RESOURCE or ANTHROPIC_FOUNDRY_BASE_URL."
        resource="$(jq -r '.[0]' <<< "$resources")"
    fi
    [[ -z "$resource" || "$resource" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]] || fail "ANTHROPIC_FOUNDRY_RESOURCE must be a resource name, not a URL."
    [[ -z "$endpoint" || "$endpoint" == https://* ]] || fail "ANTHROPIC_FOUNDRY_BASE_URL must use HTTPS."
fi

keys=(ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_FOUNDRY_API_KEY ANTHROPIC_FOUNDRY_AUTH_TOKEN ANTHROPIC_FOUNDRY_RESOURCE ANTHROPIC_FOUNDRY_BASE_URL ANTHROPIC_MODEL ANTHROPIC_DEFAULT_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL ANTHROPIC_SMALL_FAST_MODEL CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY CLAUDE_CODE_SKIP_FOUNDRY_AUTH AZURE_CLIENT_ID AZURE_CLIENT_SECRET AZURE_TENANT_ID AZURE_CLIENT_CERTIFICATE_PATH AZURE_FEDERATED_TOKEN_FILE)
for key in "${keys[@]}"; do
    unset "$key"
done
settings_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-session.XXXXXXXX")"
trap 'rm -rf "$settings_dir"' EXIT
files=("$root/claude/settings.$backend.json")
automode="${CLAUDE_AUTOMODE_ENV_FILE:-$HOME/.config/claude-code/automode.json}"
if [[ -z "${CLAUDE_AUTOMODE_ENV_FILE:-}" && ! -f "$automode" && -f "$HOME/.config/claude-code/foundry-automode.json" ]]; then
    automode="$HOME/.config/claude-code/foundry-automode.json"
fi
[[ ! -f "$automode" ]] || files=("$automode" "${files[@]}")
jq -n --args '$ARGS.positional | map({key: ., value: ""}) | from_entries' "${keys[@]}" > "$settings_dir/clear.json"
jq -s --slurpfile clear "$settings_dir/clear.json" --slurpfile base "$root/claude/settings.base.json" --slurpfile fragment "$root/claude/settings.$backend.json" \
    --arg backend "$backend" --arg resource "$resource" --arg endpoint "$endpoint" \
    --arg opus "$opus" --arg sonnet "$sonnet" --arg haiku "$haiku" '
    reduce .[] as $settings ({}; . * ($settings | .env = ((.env // {}) | with_entries(select(.key as $key | $clear[0] | has($key) | not)))))
    | .env = ($clear[0] * (.env // {}))
    | .env.ANTHROPIC_API_KEY = "" | .env.ANTHROPIC_AUTH_TOKEN = ""
    | .env.ANTHROPIC_FOUNDRY_API_KEY = "" | .env.ANTHROPIC_FOUNDRY_AUTH_TOKEN = ""
    | .env.CLAUDE_CODE_USE_BEDROCK = "0" | .env.CLAUDE_CODE_USE_VERTEX = "0"
    | .env.CLAUDE_CODE_SKIP_FOUNDRY_AUTH = "0"
    | del(.apiKeyHelper, .statusLine)
    | .apiKeyHelper = ""
    | if $backend == "foundry" then
        .env.CLAUDE_CODE_USE_FOUNDRY = "1"
        | .env.ANTHROPIC_FOUNDRY_RESOURCE = $resource
        | .env.ANTHROPIC_FOUNDRY_BASE_URL = $endpoint
        | .env.ANTHROPIC_DEFAULT_OPUS_MODEL = (if $opus != "" then $opus else $fragment[0].env.ANTHROPIC_DEFAULT_OPUS_MODEL end)
        | .env.ANTHROPIC_DEFAULT_SONNET_MODEL = (if $sonnet != "" then $sonnet else $fragment[0].env.ANTHROPIC_DEFAULT_SONNET_MODEL end)
        | .env.ANTHROPIC_DEFAULT_HAIKU_MODEL = (if $haiku != "" then $haiku else $fragment[0].env.ANTHROPIC_DEFAULT_HAIKU_MODEL end)
      else
        .env.CLAUDE_CODE_USE_FOUNDRY = "0"
        | .model = $base[0].model
        | .env.ANTHROPIC_DEFAULT_OPUS_MODEL = ""
        | .env.ANTHROPIC_DEFAULT_SONNET_MODEL = ""
        | .env.ANTHROPIC_DEFAULT_HAIKU_MODEL = ""
      end
    ' "${files[@]}" > "$settings_dir/settings.json"
claude --settings "$settings_dir/settings.json" "$@"
