#!/usr/bin/env zsh
set -euo pipefail

root="${DOTFILES:-$HOME/Developer/dotfiles/main}"
claude_dir="$root/claude"
profiles_dir="$claude_dir/profiles"
generated="$claude_dir/.local/profiles"
typeset -a linked_items=(CLAUDE.md output-styles statusline-command.sh)
codex_dir="$root/codex"
codex_profiles="$codex_dir/profiles"
codex_generated="$codex_dir/.local/profiles"
key_file="${FOUNDRY_PROXY_KEY_FILE:-$HOME/.config/foundry-entra-proxy/client.key}"
plan_root="${PLAN_HOME:-$HOME/notes/SecondBrain/4.Resources/plans}"
marker="# Codex-managed state below this line is kept when the installer regenerates the profile."
t3_settings="$HOME/.t3/userdata/settings.json"
typeset -A codex_links=(
    AGENTS.md "$root/global/AGENTS.md"
    hooks.json "$codex_dir/hooks.json"
)
credential_keys='["ANTHROPIC_API_KEY","ANTHROPIC_AUTH_TOKEN","ANTHROPIC_FOUNDRY_API_KEY","ANTHROPIC_FOUNDRY_AUTH_TOKEN","CLAUDE_CODE_OAUTH_TOKEN"]'

check=0
skip_foundry=0
typeset arg
for arg in "$@"; do
    case "$arg" in
        --check) check=1 ;;
        --skip-foundry) skip_foundry=1 ;;
        *) print -u2 "Unknown argument: $arg"; exit 1 ;;
    esac
done
link_profile_items() {
    local item
    for item in $linked_items; do link_item "$claude_dir/$item" "$1/$item"; done
    link_item "$profiles_dir/${2}/hooks" "$1/hooks"
    unlink_legacy_agents "$1"
}
command -v jq >/dev/null || { print -u2 "jq is required."; exit 1 }
umask 077
incomplete=0

die() { print -u2 "$*"; exit 1 }
problem() { print "$*"; incomplete=1 }
mode_of() { command stat -c %a "$1" 2>/dev/null || command stat -f %Lp "$1" }

typeset -a drives=("$HOME"/OneDrive*(N))
[[ "${#drives}" -le 1 ]] || die "Expected at most one ~/OneDrive* directory, found ${#drives}."
localrc_target="${drives[1]:-}/Personal/.localrc"
if [[ "${#drives}" -eq 0 ]]; then
    : # no OneDrive on this machine (Linux); use whatever ~/.localrc exists
elif [[ ! -f "$localrc_target" ]]; then
    die "OneDrive has not synced $localrc_target yet."
elif [[ -L "$HOME/.localrc" && "$(readlink "$HOME/.localrc")" == "$localrc_target" ]]; then
    :
elif [[ -e "$HOME/.localrc" || -L "$HOME/.localrc" ]]; then
    die "~/.localrc exists but is not a link to $localrc_target; move it aside and rerun."
elif [[ "$check" -eq 1 ]]; then
    problem "~/.localrc link missing"
else
    ln -s "$localrc_target" "$HOME/.localrc"
    print "Linked ~/.localrc -> $localrc_target"
fi

overrides_profile() {
    local name="$1" value="${(P)1}"
    [[ -n "$value" ]] || return 1
    case "$name" in CLAUDE_CODE_USE_*) ;; *) return 0 ;; esac
    case "${(L)value}" in
        0|false|no|off) [[ "$name" == CLAUDE_CODE_USE_FOUNDRY && "$skip_foundry" -eq 0 ]] ;;
        *) return 0 ;;
    esac
}
conflicts=""
typeset env_name
for env_name in ${(k)parameters[(R)*export*]}; do
    [[ "$env_name" == (ANTHROPIC_*|CLAUDE_CODE_USE_*|CLAUDE_CODE_OAUTH_TOKEN) ]] || continue
    [[ "$env_name" == ANTHROPIC_FOUNDRY_RESOURCE ]] && continue
    overrides_profile "$env_name" && conflicts+="$env_name " || true
done
[[ -z "$conflicts" ]] || problem "Inherited variables override profile settings; unset before launching: $conflicts"

localrc_json='{}'
if [[ -e "$HOME/.localrc" ]]; then
    localrc_json="$(zsh -c 'source ~/.localrc >/dev/null 2>&1; jq -n --arg resource "${ANTHROPIC_FOUNDRY_RESOURCE:-}" --arg all "${CLAUDE_SETTINGS_JSON:-}" --arg personal "${CLAUDE_SETTINGS_JSON_PERSONAL:-}" --arg subscription "${CLAUDE_SETTINGS_JSON_SUBSCRIPTION:-}" --arg foundry "${CLAUDE_SETTINGS_JSON_FOUNDRY:-}" "\$ARGS.named"' 2>/dev/null)" || die "Could not read ~/.localrc."
fi
typeset -A local_layers
typeset local_key local_raw local_var
for local_key in all personal subscription foundry; do
    local_var="CLAUDE_SETTINGS_JSON${${local_key:#all}:+_${(U)local_key}}"
    local_raw="$(jq -r --arg k "$local_key" '.[$k] // ""' <<< "$localrc_json")"
    if [[ -z "$local_raw" ]]; then
        local_layers[$local_key]='{}'
    else
        local_layers[$local_key]="$(jq -ce 'if type == "object" then . else error("not an object") end' <<< "$local_raw" 2>/dev/null)" ||
            die "~/.localrc: $local_var must be a JSON object."
        print "Merging $local_var from ~/.localrc"
    fi
done
resource="${ANTHROPIC_FOUNDRY_RESOURCE:-$(jq -r '.resource // ""' <<< "$localrc_json")}"
[[ -z "$resource" ]] || [[ "$resource" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]] || die "ANTHROPIC_FOUNDRY_RESOURCE must be a resource name, not a URL."

automode="$HOME/.config/claude-code/automode.json"
[[ -f "$automode" ]] || automode="$HOME/.config/claude-code/foundry-automode.json"
auto='{}'
[[ ! -f "$automode" ]] || auto="$(jq -c 'if .autoMode.environment then {autoMode: {environment: .autoMode.environment}} else {} end' "$automode")"

build() {
    local -a layers=("$claude_dir/settings.base.json" "$profiles_dir/$1/settings.json")
    jq -S -s --arg profile "$1" --arg resource "$resource" --arg home "$HOME" --argjson auto "$auto" \
        --argjson local_all "${local_layers[all]}" --argjson local_profile "${local_layers[$1]}" '
        reduce (.[], $local_all, $local_profile) as $layer ({};
            (reduce (($layer.hooks // {}) | to_entries[]) as $e (.hooks // {};
                .[$e.key] = reduce $e.value[] as $h (.[$e.key] // []; if any(.[]; . == $h) then . else . + [$h] end))) as $hooks
            | ((.enabledMcpjsonServers // []) + ($layer.enabledMcpjsonServers // []) | unique) as $mcp
            | . * $layer | .hooks = $hooks | .enabledMcpjsonServers = $mcp)
        | .env += {CLAUDE_CODE_USE_BEDROCK: "0", CLAUDE_CODE_USE_VERTEX: "0"}
        | .extraKnownMarketplaces."fleet-local" = {source: {source: "directory", path: ($home + "/.local/share/fleet-marketplace")}}
        | if $profile == "foundry" then . * $auto | .env.ANTHROPIC_FOUNDRY_RESOURCE = $resource
          else .env.CLAUDE_CODE_USE_FOUNDRY = "0" | .forceLoginMethod = "claudeai" end' "${layers[@]}"
}

link_item() {
    local src="$1" dest="$2"
    [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]] && return
    if [[ "$check" -eq 1 ]]; then
        problem "$dest is not linked to $src"
    elif [[ -L "$dest" || ! -e "$dest" ]]; then
        ln -sfn "$src" "$dest" && print "Linked $dest -> $src"
    else
        problem "$dest exists and is not a symlink; skipping."
    fi
}

unlink_legacy_agents() {
    local dest="$1/agents"
    [[ -L "$dest" && "$(readlink "$dest")" == "$claude_dir/agents" ]] || return 0
    if [[ "$check" -eq 1 ]]; then
        problem "$dest is a stale link to $claude_dir/agents"
    else
        rm "$dest" && print "Removed stale $dest"
    fi
}

install_plugins() {
    local dir="$1" settings="$2" have name src id
    command -v claude >/dev/null || { problem "claude is not installed; skipped plugins for $dir"; return }
    have="$(CLAUDE_CONFIG_DIR="$dir" claude plugin marketplace list --json)"
    while IFS=$'\t' read -r name src; do
        jq -e --arg n "$name" 'any(.[]; .name == $n)' <<< "$have" >/dev/null ||
            CLAUDE_CONFIG_DIR="$dir" claude plugin marketplace add "$src" || problem "Failed to add marketplace $name to $dir"
    done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[] | [.key, (.value.source.repo // .value.source.url // .value.source.path)] | @tsv' <<< "$settings")
    have="$(CLAUDE_CONFIG_DIR="$dir" claude plugin list --json)"
    while read -r id; do
        jq -e --arg id "$id" 'any(.[]; .id == $id)' <<< "$have" >/dev/null ||
            CLAUDE_CONFIG_DIR="$dir" claude plugin install "$id" || problem "Failed to install plugin $id in $dir"
    done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' <<< "$settings")
}

install_fleet() {
    local dir="$1"
    command -v fleet >/dev/null || return 0
    CLAUDE_CONFIG_DIR="$dir" fleet install </dev/null >/dev/null || problem "fleet install failed for $dir"
}

sync_t3_claude() {
    [[ -f "$t3_settings" ]] || return 0
    local want
    want="$(jq --arg bin "claude-$1" --arg home "~/.claude-$1" --arg name ".claude-$1" --arg profile "$1" '
        if (.providerInstances | type) == "object" then
            .providerInstances |= with_entries(
                (.value.config.homePath // "") as $h
                | if .value.driver == "claudeAgent" and (($h | contains($name)) or ($profile == "personal" and ($h == "" or $h == "~/.claude")))
                then .value.config += {homePath: $home, binaryPath: $bin}
                else . end)
        else . end' "$t3_settings" 2>/dev/null)" || { problem "Could not parse $t3_settings"; return }
    [[ "$want" != "$(jq . "$t3_settings")" ]] || return 0
    if [[ "$check" -eq 1 ]]; then
        problem "T3 Code: a Claude instance for $1 has the wrong home or binary in $t3_settings"
    else
        print -r -- "$want" > "$t3_settings.tmp" && cat "$t3_settings.tmp" > "$t3_settings" && rm "$t3_settings.tmp" &&
            print "Pointed the T3 Code Claude $1 instance at ~/.claude-$1 (restart T3 Code to apply)"
    fi
}

[[ ! -L "$generated" && ! -L "${generated:h}" ]] || die "Refusing symlinked generated directory: $generated"
[[ "$check" -eq 1 ]] || { mkdir -p "$generated"; chmod 700 "$generated" }

typeset profile dir dest target want
for profile in personal subscription foundry; do
    if [[ "$profile" == foundry ]]; then
        [[ "$skip_foundry" -eq 0 ]] || continue
        if [[ -z "$resource" && "${#drives}" -eq 0 ]]; then
            print "Claude Foundry skipped: no ~/OneDrive* directory and ANTHROPIC_FOUNDRY_RESOURCE is unset."
            continue
        elif [[ -z "$resource" ]]; then
            problem "Claude Foundry skipped: ANTHROPIC_FOUNDRY_RESOURCE is unset (export it from ~/.localrc)."
            continue
        fi
    fi
    dir="$HOME/.claude-$profile"
    dest="$dir/settings.json"
    target="$generated/$profile.json"
    [[ ! -L "$dir" ]] || die "Refusing symlinked profile directory: $dir"
    want="$(build "$profile")"
    if jq -e --argjson keys "$credential_keys" '.apiKeyHelper or ((.env // {}) | keys | any(IN($keys[])))' <<< "$want" >/dev/null; then
        die "$profile: settings layers must not contain credentials (apiKeyHelper or API keys/tokens)."
    fi

    if [[ "$check" -eq 1 ]]; then
        [[ -d "$dir" && "$(mode_of "$dir")" == 700 ]] || problem "$profile: $dir must exist with mode 700"
        [[ -L "$dest" && "$(readlink "$dest")" == "$target" ]] || problem "$profile: $dest is not linked to $target"
        [[ -f "$target" && "$(mode_of "$target")" == 600 ]] || problem "$profile: $target must exist with mode 600"
        [[ -f "$target" && "$(jq -S . "$target")" == "$want" ]] || problem "$profile: generated settings are stale"
        [[ -d "$dir/skills" && ! -L "$dir/skills" ]] || problem "$profile: $dir/skills must be a real directory"
        link_profile_items "$dir" "$profile"
        sync_t3_claude "$profile"
        continue
    fi

    mkdir -p "$dir"
    chmod 700 "$dir"
    if [[ ! -f "$target" || "$(jq -S . "$target")" != "$want" ]]; then
        print -r -- "$want" > "$target.tmp" && mv "$target.tmp" "$target" && print "Generated $target"
    fi
    chmod 600 "$target"
    if [[ ! -L "$dest" || "$(readlink "$dest")" != "$target" ]]; then
        if [[ -e "$dest" || -L "$dest" ]]; then
            mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)" && print "Backed up existing $dest"
        fi
        ln -s "$target" "$dest" && print "Linked $dest -> $target"
    fi
    link_profile_items "$dir" "$profile"
    [[ ! -L "$dir/skills" ]] || die "Refusing symlinked skills directory: $dir/skills"
    mkdir -p "$dir/skills"
    if command -v skillctl >/dev/null; then
        CLAUDE_CONFIG_DIR="$dir" skillctl sync --global >/dev/null || problem "skillctl sync failed for $dir"
    else
        problem "skillctl is not installed; $dir/skills left empty"
    fi
    install_plugins "$dir" "$want"
    install_fleet "$dir"
    sync_t3_claude "$profile"
    print "Profile ready: claude $profile ($dir)"
done

unlink_legacy_overlay() {
    local dest="$HOME/.codex/foundry.config.toml"
    [[ -L "$dest" && "$(readlink "$dest")" == */codex/foundry.config.toml ]] || return 0
    if [[ "$check" -eq 1 ]]; then
        problem "$dest is a stale overlay link; Foundry now uses its own CODEX_HOME"
    else
        rm "$dest" && print "Removed stale $dest"
    fi
}

build_codex() {
    print -r -- "$(<"$codex_profiles/$1/config.toml")"
    print
    print "[sandbox_workspace_write]"
    print -r -- "writable_roots = [\"$plan_root\"]"
}

managed_part() {
    [[ -f "$1" ]] || return 0
    awk -v m="$marker" '$0 == m { exit } { print }' "$1"
}

state_part() {
    [[ -f "$1" ]] || return 0
    awk -v m="$marker" 'found { print } $0 == m { found = 1 }' "$1"
}

sync_t3_codex() {
    [[ -f "$t3_settings" ]] || return 0
    local want
    want="$(jq --arg bin "$root/bin/codex-foundry" --arg home "~/.codex-$1" --arg name ".codex-$1" '
        if (.providerInstances | type) == "object" then
            .providerInstances |= with_entries(
                if .value.driver == "codex" and (((.value.config.homePath // "") + " " + (.value.config.shadowHomePath // "")) | contains($name))
                then .value.config += {homePath: $home, shadowHomePath: "", binaryPath: $bin}
                else . end)
        else . end' "$t3_settings" 2>/dev/null)" || { problem "Could not parse $t3_settings"; return }
    [[ "$want" != "$(jq . "$t3_settings")" ]] || return 0
    if [[ "$check" -eq 1 ]]; then
        problem "T3 Code: a Codex instance for $1 has the wrong home, shadow home or binary in $t3_settings"
    else
        print -r -- "$want" > "$t3_settings.tmp" && cat "$t3_settings.tmp" > "$t3_settings" && rm "$t3_settings.tmp" &&
            print "Pointed the T3 Code Codex $1 instance at ~/.codex-$1 (restart T3 Code to apply)"
    fi
}

unlink_legacy_overlay
[[ ! -L "$codex_generated" && ! -L "${codex_generated:h}" ]] || die "Refusing symlinked generated directory: $codex_generated"
[[ "$check" -eq 1 ]] || { mkdir -p "$codex_generated"; chmod 700 "$codex_generated" }

typeset state item
for profile in foundry; do
    [[ "$skip_foundry" -eq 0 ]] || continue
    if [[ ! -r "$key_file" ]]; then
        if [[ "${#drives}" -eq 0 ]]; then
            print "Codex Foundry skipped: no foundry-entra-proxy client key at $key_file."
        else
            problem "Codex Foundry skipped: no client key at $key_file (run foundry-entra-proxy/install.sh in clitools)."
        fi
        continue
    fi
    dir="$HOME/.codex-$profile"
    dest="$dir/config.toml"
    target="$codex_generated/$profile.toml"
    [[ ! -L "$dir" ]] || die "Refusing symlinked profile directory: $dir"
    want="$(build_codex "$profile")"

    if [[ "$check" -eq 1 ]]; then
        [[ -d "$dir" && "$(mode_of "$dir")" == 700 ]] || problem "codex $profile: $dir must exist with mode 700"
        [[ -L "$dest" && "$(readlink "$dest")" == "$target" ]] || problem "codex $profile: $dest is not linked to $target"
        [[ -f "$target" && "$(mode_of "$target")" == 600 ]] || problem "codex $profile: $target must exist with mode 600"
        [[ "$(managed_part "$target")" == "$want" ]] || problem "codex $profile: generated config is stale"
        [[ ! -e "$dir/auth.json" ]] || problem "codex $profile: $dir/auth.json holds a ChatGPT login; remove it, Foundry uses the proxy key"
        for item in ${(k)codex_links}; do link_item "${codex_links[$item]}" "$dir/$item"; done
        sync_t3_codex "$profile"
        continue
    fi

    mkdir -p "$dir"
    chmod 700 "$dir"
    if [[ "$(managed_part "$target")" != "$want" ]]; then
        state="$(state_part "$target")"
        { print -r -- "$want"; print; print -r -- "$marker"; [[ -z "$state" ]] || print -r -- "$state" } > "$target.tmp"
        mv "$target.tmp" "$target" && print "Generated $target"
    fi
    chmod 600 "$target"
    if [[ ! -L "$dest" || "$(readlink "$dest")" != "$target" ]]; then
        if [[ -e "$dest" || -L "$dest" ]]; then
            mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)" && print "Backed up existing $dest"
        fi
        ln -s "$target" "$dest" && print "Linked $dest -> $target"
    fi
    for item in ${(k)codex_links}; do link_item "${codex_links[$item]}" "$dir/$item"; done
    [[ ! -e "$dir/auth.json" ]] || problem "codex $profile: $dir/auth.json holds a ChatGPT login; remove it, Foundry uses the proxy key"
    [[ ! -L "$dir/skills" ]] || die "Refusing symlinked skills directory: $dir/skills"
    mkdir -p "$dir/skills"
    if command -v skillctl >/dev/null; then
        CODEX_HOME="$dir" skillctl sync --global >/dev/null || problem "skillctl sync failed for $dir"
    else
        problem "skillctl is not installed; $dir/skills left empty"
    fi
    sync_t3_codex "$profile"
    print "Profile ready: codex $profile ($dir)"
done

if [[ "$check" -eq 0 ]]; then
    if command -v fleet >/dev/null; then
        if command -v codex >/dev/null || [[ -d "$HOME/.codex" ]]; then
            fleet install codex </dev/null >/dev/null || problem "fleet install codex failed"
        fi
        fleet_detection_src="$root/config/fleet/detection"
        fleet_detection_dest="$HOME/.config/fleet/detection"
        mkdir -p "$HOME/.config/fleet"
        [[ "$fleet_detection_dest" -ef "$fleet_detection_src" ]] || link_item "$fleet_detection_src" "$fleet_detection_dest"
        print "Fleet hooks wired for Claude profiles and Codex; Copilot is discovered via @fleet_discover_agents plus the linked detection manifest."
    else
        problem "fleet is not installed; agent hooks skipped (brew bundle installs it)"
    fi
fi

exit $(( incomplete ? 2 : 0 ))
