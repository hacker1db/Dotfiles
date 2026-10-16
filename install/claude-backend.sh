#!/usr/bin/env bash
# Select and link the machine-specific Claude Code global settings.
#
# Resolution order for the backend:
#   1. $CLAUDE_CODE_BACKEND environment variable  (foundry | anthropic)
#   2. marker file (default: ~/.config/claude-code/backend), containing the word
#      foundry or anthropic
#   3. default: anthropic
#
# The chosen backend fragment (claude/settings.<backend>.json) is deep-merged on
# top of the shared base (claude/settings.base.json) with jq, written to a
# gitignored generated file, and symlinked to ~/.claude/settings.json.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$DOTFILES/install/lib/log.sh"

CLAUDE_DIR="$DOTFILES/claude"
BASE="$CLAUDE_DIR/settings.base.json"
GEN_DIR="$CLAUDE_DIR/.local"
GEN="$GEN_DIR/settings.generated.json"
DEST="$HOME/.claude/settings.json"
MARKER="${CLAUDE_CODE_BACKEND_MARKER:-$HOME/.config/claude-code/backend}"

resolve_backend() {
  local arg="${1:-}"
  if [ -n "$arg" ]; then
    echo "$arg"
    return
  fi
  if [ -n "${CLAUDE_CODE_BACKEND:-}" ]; then
    echo "$CLAUDE_CODE_BACKEND"
    return
  fi
  if [ -f "$MARKER" ]; then
    tr -d '[:space:]' < "$MARKER"
    return
  fi
  echo "anthropic"
}

backend="$(resolve_backend "${2:-}")"
case "$backend" in
  foundry | anthropic) ;;
  *)
    error "Unknown Claude backend '$backend' (expected: foundry or anthropic)"
    exit 1
    ;;
esac

FRAGMENT="$CLAUDE_DIR/settings.$backend.json"

command -v jq >/dev/null 2>&1 || { error "jq is required but not installed"; exit 1; }
[ -f "$BASE" ] || { error "Missing base settings: $BASE"; exit 1; }
[ -f "$FRAGMENT" ] || { error "Missing fragment: $FRAGMENT"; exit 1; }

# The generated file can carry credentials from the autoMode input, so keep it
# private to the current user (mktemp creates files with mode 0600).
mkdir -p "$GEN_DIR" "$HOME/.claude"
chmod 700 "$GEN_DIR"

# Merge into a temporary file and move it into place only on success, so a
# failed merge never truncates the settings file already linked into ~/.claude.
TMP_GEN="$(mktemp "$GEN_DIR/settings.generated.XXXXXX")"
trap 'rm -f "$TMP_GEN"' EXIT

# Deep-merge: keys in the fragment win, env objects are merged key by key.
# Local autoMode.environment file — not committed to git, shared across backends.
# Falls back to the legacy foundry-automode.json name for backward compatibility.
_automode_default="$HOME/.config/claude-code/automode.json"
_automode_legacy="$HOME/.config/claude-code/foundry-automode.json"
if [ -z "${CLAUDE_AUTOMODE_ENV_FILE:-}" ] && [ ! -f "$_automode_default" ] && [ -f "$_automode_legacy" ]; then
  _automode_default="$_automode_legacy"
fi
LOCAL_AUTOMODE="${CLAUDE_AUTOMODE_ENV_FILE:-$_automode_default}"

if [ "$backend" = "foundry" ]; then
  # Resource name comes from $ANTHROPIC_FOUNDRY_RESOURCE; if empty, discover it
  # via the Azure CLI (requires `az login`).
  resource="${ANTHROPIC_FOUNDRY_RESOURCE:-}"
  if [ -z "$resource" ]; then
    command -v az >/dev/null 2>&1 || {
      error "ANTHROPIC_FOUNDRY_RESOURCE is unset and the Azure CLI (az) is not installed."
      exit 1
    }
    resource="$(az cognitiveservices account list --query "[?kind=='AIServices'].name | [0]" -o tsv 2>/dev/null || true)"
  fi
  if [ -z "$resource" ] || [ "$resource" = "null" ]; then
    error "Could not resolve a Foundry resource name. Run 'az login' or set ANTHROPIC_FOUNDRY_RESOURCE."
    exit 1
  fi
  if [ -f "$LOCAL_AUTOMODE" ]; then
    jq -s --arg res "$resource" '.[0] * .[1] * .[2] * .[3] | .env.ANTHROPIC_FOUNDRY_RESOURCE = $res' "$BASE" "$CLAUDE_DIR/settings.work.json" "$FRAGMENT" "$LOCAL_AUTOMODE" > "$TMP_GEN"
    info "Resolved Claude backend: foundry (resource: $resource, autoMode: $LOCAL_AUTOMODE)"
  else
    jq -s --arg res "$resource" '.[0] * .[1] * .[2] | .env.ANTHROPIC_FOUNDRY_RESOURCE = $res' "$BASE" "$CLAUDE_DIR/settings.work.json" "$FRAGMENT" > "$TMP_GEN"
    info "Resolved Claude backend: foundry (resource: $resource)"
  fi
else
  if [ -f "$LOCAL_AUTOMODE" ]; then
    jq -s '.[0] * .[1] * .[2] * .[3]' "$BASE" "$CLAUDE_DIR/settings.work.json" "$FRAGMENT" "$LOCAL_AUTOMODE" > "$TMP_GEN"
    info "Resolved Claude backend: $backend (autoMode: $LOCAL_AUTOMODE)"
  else
    jq -s '.[0] * .[1] * .[2]' "$BASE" "$CLAUDE_DIR/settings.work.json" "$FRAGMENT" > "$TMP_GEN"
    info "Resolved Claude backend: $backend"
  fi
fi

# Preserve user-owned settings from the current ~/.claude/settings.json: a
# custom statusLine and any hook registrations that do not run a managed
# command. Managed hooks always come from the repository fragments.
if [ -f "$DEST" ] && jq -e 'type == "object"' "$DEST" >/dev/null 2>&1; then
  TMP_MERGED="$(mktemp "$GEN_DIR/settings.merged.XXXXXX")"
  trap 'rm -f "$TMP_GEN" "$TMP_MERGED"' EXIT
  jq -s '
    .[0] as $gen | .[1] as $old
    | [($gen.hooks // {})[][] | .hooks[]? | .command] as $managed
    | $gen
    | if $old.statusLine then .statusLine = $old.statusLine else . end
    | reduce (($old.hooks // {}) | to_entries[]) as $e (.;
        reduce ($e.value[]
                | select([.hooks[]?.command] | all(. as $c | $managed | index([$c]) | not))) as $r (.;
          if ((.hooks[$e.key] // []) | index([$r])) then .
          else .hooks[$e.key] = ((.hooks[$e.key] // []) + [$r]) end))
  ' "$TMP_GEN" "$DEST" > "$TMP_MERGED"
  mv -f "$TMP_MERGED" "$TMP_GEN"
fi

chmod 600 "$TMP_GEN"
mv -f "$TMP_GEN" "$GEN"
# install.sh sources this script; do not leave the cleanup trap behind.
trap - EXIT

link() {
  rm -f "$DEST"
  ln -s "$GEN" "$DEST"
  echo "Linked $DEST -> $GEN"
}

if [ -L "$DEST" ]; then
  if [ "$(readlink "$DEST")" != "$GEN" ]; then
    link
  else
    echo "~/.claude/settings.json already symlinked correctly."
  fi
elif [ ! -e "$DEST" ]; then
  link
else
  warning "~/.claude/settings.json exists and is not a symlink; backing up to settings.json.bak"
  mv "$DEST" "$DEST.bak"
  link
fi

success "Claude Code settings ready for backend: $backend"
