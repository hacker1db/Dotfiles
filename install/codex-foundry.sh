#!/usr/bin/env bash
# Generate a Codex provider home for Microsoft Foundry OpenAI deployments.
#
# Authentication is command-backed: Codex invokes bin/azure-openai-token,
# which obtains a short-lived Entra token from the Azure CLI login.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$DOTFILES/install/lib/log.sh"

if [ "${1:-}" = "codex-foundry" ]; then
  shift
fi

resource="${CODEX_FOUNDRY_RESOURCE:-${AZURE_OPENAI_RESOURCE:-${ANTHROPIC_FOUNDRY_RESOURCE:-}}}"
model="${CODEX_FOUNDRY_MODEL:-}"
codex_home="${CODEX_FOUNDRY_HOME:-$HOME/.codex_foundry}"

usage() {
  cat >&2 <<'EOF'
Usage: ./install.sh codex-foundry --resource RESOURCE --model DEPLOYMENT

The resource and model may also be supplied with:
  CODEX_FOUNDRY_RESOURCE
  CODEX_FOUNDRY_MODEL
  CODEX_FOUNDRY_HOME
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --resource)
      [ "$#" -ge 2 ] || usage
      resource="$2"
      shift 2
      ;;
    --model)
      [ "$#" -ge 2 ] || usage
      model="$2"
      shift 2
      ;;
    --home)
      [ "$#" -ge 2 ] || usage
      codex_home="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      error "Unknown argument: $1"
      usage
      ;;
  esac
done

[ -n "$resource" ] || {
  error "A Foundry resource is required. Set CODEX_FOUNDRY_RESOURCE or use --resource."
  exit 1
}
[ -n "$model" ] || {
  error "A Foundry deployment name is required. Set CODEX_FOUNDRY_MODEL or use --model."
  exit 1
}

for value in "$resource" "$model"; do
  if [[ ! "$value" =~ ^[A-Za-z0-9._-]+$ ]]; then
    error "Resource and deployment names may contain only letters, numbers, dots, underscores, and hyphens."
    exit 1
  fi
done

TOKEN_HELPER="$DOTFILES/bin/azure-openai-token"
[ -x "$TOKEN_HELPER" ] || {
  error "Token helper is missing or not executable: $TOKEN_HELPER"
  exit 1
}
AUTH_ARGS='["-c", "exec \"$HOME/.dotfiles/bin/azure-openai-token\""]'

mkdir -p "$codex_home"
config="$codex_home/config.toml"
if [ -e "$config" ] && [ ! -L "$config" ]; then
  warning "$config exists; backing it up to ${config}.bak"
  mv "$config" "${config}.bak"
fi

cat > "$config" <<EOF
model = "$model"
model_provider = "azure"
model_reasoning_effort = "medium"

[model_providers.azure]
name = "Microsoft Foundry OpenAI"
base_url = "https://${resource}.openai.azure.com/openai/v1"
wire_api = "responses"

[model_providers.azure.auth]
command = "/bin/sh"
args = $AUTH_ARGS
timeout_ms = 10000
refresh_interval_ms = 300000
EOF

chmod 600 "$config"
info "Configured Codex Foundry home: $codex_home"
info "Resource: $resource"
info "Deployment: $model"
success "Codex Foundry uses Azure CLI token authentication; no API key is configured."
