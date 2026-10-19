#!/usr/bin/env bash
# Generate and link the three Claude Code profiles: ~/.claude-personal,
# ~/.claude-subscription and ~/.claude-foundry.
#
# Each profile's settings.json links to claude/.local/profiles/<profile>.json,
# a jq deep merge of claude/settings.base.json and claude/profiles/<profile>/settings.json
# (Foundry adds local autoMode.environment and the resource). Each profile's hooks/
# links to claude/profiles/<profile>/hooks.
# The Foundry resource comes from $ANTHROPIC_FOUNDRY_RESOURCE (exported by ~/.localrc).
#
# Usage: claude-profiles.sh [--check] [--skip-foundry]
# Exit: 0 ready, 1 hard error, 2 incomplete (missing resource, conflicts, stale state).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
claude_dir="$root/claude"
profiles_dir="$claude_dir/profiles"
generated="$claude_dir/.local/profiles"
linked_items=(CLAUDE.md commands output-styles statusline-command.sh)
credential_keys='["ANTHROPIC_API_KEY","ANTHROPIC_AUTH_TOKEN","ANTHROPIC_FOUNDRY_API_KEY","ANTHROPIC_FOUNDRY_AUTH_TOKEN","CLAUDE_CODE_OAUTH_TOKEN"]'

check=0
skip_foundry=0
for arg in "$@"; do
    case "$arg" in
        --check) check=1 ;;
        --skip-foundry) skip_foundry=1 ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done
command -v jq >/dev/null || { echo "jq is required." >&2; exit 1; }
umask 077
incomplete=0

die() { echo "$*" >&2; exit 1; }
problem() { echo "$*"; incomplete=1; }
mode_of() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

# ~/.localrc must link to the OneDrive copy so ANTHROPIC_FOUNDRY_RESOURCE follows the user.
shopt -s nullglob
drives=("$HOME"/OneDrive*)
shopt -u nullglob
[ "${#drives[@]}" -le 1 ] || die "Expected at most one ~/OneDrive* directory, found ${#drives[@]}."
localrc_target="${drives[0]:-}/Personal/.localrc"
if [ "${#drives[@]}" -eq 0 ]; then
    : # no OneDrive on this machine (Linux); use whatever ~/.localrc exists
elif [ ! -f "$localrc_target" ]; then
    die "OneDrive has not synced $localrc_target yet."
elif [ -L "$HOME/.localrc" ] && [ "$(readlink "$HOME/.localrc")" = "$localrc_target" ]; then
    :
elif [ -e "$HOME/.localrc" ] || [ -L "$HOME/.localrc" ]; then
    die "~/.localrc exists but is not a link to $localrc_target; move it aside and rerun."
elif [ "$check" -eq 1 ]; then
    problem "~/.localrc link missing"
else
    ln -s "$localrc_target" "$HOME/.localrc"
    echo "Linked ~/.localrc -> $localrc_target"
fi

conflicts="$(compgen -e | grep -E '^(ANTHROPIC_|CLAUDE_CODE_USE_|CLAUDE_CODE_OAUTH_TOKEN$)' | grep -vx ANTHROPIC_FOUNDRY_RESOURCE | while read -r name; do [ -n "${!name}" ] && echo "$name"; done | tr '\n' ' ' || true)"
[ -z "$conflicts" ] || problem "Inherited variables override profile settings; unset before launching: $conflicts"

resource="${ANTHROPIC_FOUNDRY_RESOURCE:-}"
if [ -z "$resource" ] && command -v zsh >/dev/null; then
    resource="$(zsh -c 'source ~/.localrc >/dev/null 2>&1; print -r -- "${ANTHROPIC_FOUNDRY_RESOURCE:-}"' 2>/dev/null || true)"
fi
[ -z "$resource" ] || [[ "$resource" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]] || die "ANTHROPIC_FOUNDRY_RESOURCE must be a resource name, not a URL."

automode="$HOME/.config/claude-code/automode.json"
[ -f "$automode" ] || automode="$HOME/.config/claude-code/foundry-automode.json"
auto='{}'
[ ! -f "$automode" ] || auto="$(jq -c 'if .autoMode.environment then {autoMode: {environment: .autoMode.environment}} else {} end' "$automode")"

build() {
    local layers=("$claude_dir/settings.base.json" "$profiles_dir/$1/settings.json")
    jq -S -s --arg profile "$1" --arg resource "$resource" --argjson auto "$auto" '
        reduce .[] as $layer ({}; . * $layer)
        | .env += {CLAUDE_CODE_USE_BEDROCK: "0", CLAUDE_CODE_USE_VERTEX: "0"}
        | if $profile == "foundry" then . * $auto | .env.ANTHROPIC_FOUNDRY_RESOURCE = $resource
          else .env.CLAUDE_CODE_USE_FOUNDRY = "0" | .forceLoginMethod = "claudeai" end' "${layers[@]}"
}

link_item() {
    local src="$1" dest="$2"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        return
    elif [ "$check" -eq 1 ]; then
        problem "$dest is not linked to $src"
    elif [ -L "$dest" ] || [ ! -e "$dest" ]; then
        ln -sfn "$src" "$dest"
        echo "Linked $dest -> $src"
    else
        problem "$dest exists and is not a symlink; skipping."
    fi
}

# skillctl installs subagents from the skills repository; remove the agents link this script used to own.
unlink_legacy_agents() {
    local dest="$1/agents"
    [ -L "$dest" ] && [ "$(readlink "$dest")" = "$claude_dir/agents" ] || return 0
    if [ "$check" -eq 1 ]; then
        problem "$dest is a stale link to $claude_dir/agents"
    else
        rm "$dest"
        echo "Removed stale $dest"
    fi
}

install_plugins() {
    local dir="$1" settings="$2" have name src id
    command -v claude >/dev/null || { problem "claude is not installed; skipped plugins for $dir"; return; }
    have="$(CLAUDE_CONFIG_DIR="$dir" claude plugin marketplace list --json)"
    while IFS=$'\t' read -r name src; do
        jq -e --arg n "$name" 'any(.[]; .name == $n)' <<< "$have" >/dev/null ||
            CLAUDE_CONFIG_DIR="$dir" claude plugin marketplace add "$src" || problem "Failed to add marketplace $name to $dir"
    done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[] | [.key, (.value.source.repo // .value.source.url)] | @tsv' <<< "$settings")
    have="$(CLAUDE_CONFIG_DIR="$dir" claude plugin list --json)"
    while read -r id; do
        jq -e --arg id "$id" 'any(.[]; .id == $id)' <<< "$have" >/dev/null ||
            CLAUDE_CONFIG_DIR="$dir" claude plugin install "$id" || problem "Failed to install plugin $id in $dir"
    done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' <<< "$settings")
}

[ ! -L "$generated" ] && [ ! -L "$(dirname "$generated")" ] || die "Refusing symlinked generated directory: $generated"
[ "$check" -eq 1 ] || { mkdir -p "$generated"; chmod 700 "$generated"; }

for profile in personal subscription foundry; do
    if [ "$profile" = foundry ]; then
        [ "$skip_foundry" -eq 0 ] || continue
        if [ -z "$resource" ]; then
            if [ "${#drives[@]}" -eq 0 ]; then
                echo "Foundry skipped: no ~/OneDrive* directory and ANTHROPIC_FOUNDRY_RESOURCE is unset."
            else
                problem "Foundry skipped: ANTHROPIC_FOUNDRY_RESOURCE is unset (export it from ~/.localrc)."
            fi
            continue
        fi
    fi
    dir="$HOME/.claude-$profile"
    dest="$dir/settings.json"
    target="$generated/$profile.json"
    [ ! -L "$dir" ] || die "Refusing symlinked profile directory: $dir"
    want="$(build "$profile")"
    if jq -e --argjson keys "$credential_keys" '.apiKeyHelper or ((.env // {}) | keys | any(IN($keys[])))' <<< "$want" >/dev/null; then
        die "$profile: settings layers must not contain credentials (apiKeyHelper or API keys/tokens)."
    fi

    if [ "$check" -eq 1 ]; then
        [ -d "$dir" ] && [ "$(mode_of "$dir")" = 700 ] || problem "$profile: $dir must exist with mode 700"
        [ -L "$dest" ] && [ "$(readlink "$dest")" = "$target" ] || problem "$profile: $dest is not linked to $target"
        [ -f "$target" ] && [ "$(mode_of "$target")" = 600 ] || problem "$profile: $target must exist with mode 600"
        [ -f "$target" ] && [ "$(jq -S . "$target")" = "$want" ] || problem "$profile: generated settings are stale"
        [ -d "$dir/skills" ] && [ ! -L "$dir/skills" ] || problem "$profile: $dir/skills must be a real directory"
        for item in "${linked_items[@]}"; do link_item "$claude_dir/$item" "$dir/$item"; done
        link_item "$profiles_dir/$profile/hooks" "$dir/hooks"
        unlink_legacy_agents "$dir"
        continue
    fi

    mkdir -p "$dir"
    chmod 700 "$dir"
    if [ ! -f "$target" ] || [ "$(jq -S . "$target")" != "$want" ]; then
        printf '%s\n' "$want" > "$target.tmp"
        mv "$target.tmp" "$target"
        echo "Generated $target"
    fi
    chmod 600 "$target"
    if [ ! -L "$dest" ] || [ "$(readlink "$dest")" != "$target" ]; then
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)"
            echo "Backed up existing $dest"
        fi
        ln -s "$target" "$dest"
        echo "Linked $dest -> $target"
    fi
    for item in "${linked_items[@]}"; do link_item "$claude_dir/$item" "$dir/$item"; done
    link_item "$profiles_dir/$profile/hooks" "$dir/hooks"
    unlink_legacy_agents "$dir"
    [ ! -L "$dir/skills" ] || die "Refusing symlinked skills directory: $dir/skills"
    mkdir -p "$dir/skills"
    if command -v skillctl >/dev/null; then
        CLAUDE_CONFIG_DIR="$dir" skillctl sync --global >/dev/null || problem "skillctl sync failed for $dir"
    else
        problem "skillctl is not installed; $dir/skills left empty"
    fi
    install_plugins "$dir" "$want"
    echo "Profile ready: $profile ($dir)"
done

exit $((incomplete ? 2 : 0))
