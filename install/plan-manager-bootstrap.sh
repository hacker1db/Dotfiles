#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -euo pipefail
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd -P)"
source "$DOTFILES/install/lib/log.sh"
source "$DOTFILES/install/lib/env.sh"

if [ -z "${PLAN_MANAGER_REPO_DIR:-}" ] && PLAN_OWNER="$(github_owner 2>/dev/null)"; then
    PLAN_MANAGER_REPO_DIR="$(find_github_checkout "$PLAN_OWNER/plan-manager" || true)"
fi
PLAN_REPO_DIR="${PLAN_MANAGER_REPO_DIR:-$HOME/Developer/plan-manager}"
PLAN_MANAGER_UPSTREAM_OWNER="hacker1db"
LOCAL_BIN="$HOME/.local/bin"
PLAN_LINK="$LOCAL_BIN/plan"
PLAN_ROOT="${PLAN_HOME:-$HOME/notes/SecondBrain/4.Resources/plans}"

canonical_dir() {
    (cd "$1" 2>/dev/null && pwd -P)
}

backup_path() {
    local path="$1"
    local stamp candidate suffix
    stamp="$(date +%Y%m%d%H%M%S)"
    candidate="${path}.backup-${stamp}"
    suffix=2
    while [ -e "$candidate" ] || [ -L "$candidate" ]; do
        candidate="${path}.backup-${stamp}-${suffix}"
        suffix=$((suffix + 1))
    done
    printf '%s\n' "$candidate"
}

git_common_dir() {
    local worktree="$1"
    local common
    common="$(git -C "$worktree" rev-parse --git-common-dir 2>/dev/null)" || return 1
    if [[ "$common" = /* ]]; then
        canonical_dir "$common"
    else
        canonical_dir "$worktree/$common"
    fi
}

valid_worktree() {
    local path="$1"
    local inside top actual
    [ -d "$path" ] || return 1
    inside="$(git -C "$path" rev-parse --is-inside-work-tree 2>/dev/null)" || return 1
    [ "$inside" = "true" ] || return 1
    top="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null)" || return 1
    top="$(canonical_dir "$top")" || return 1
    actual="$(canonical_dir "$path")" || return 1
    [ "$top" = "$actual" ]
}

configured_common_dir() {
    local repo_dir="$1"
    if [ -d "$repo_dir/.bare" ] &&
        [ "$(git --git-dir="$repo_dir/.bare" rev-parse --is-bare-repository 2>/dev/null || true)" = "true" ]; then
        canonical_dir "$repo_dir/.bare"
        return
    fi
    if valid_worktree "$repo_dir"; then
        git_common_dir "$repo_dir"
        return
    fi
    return 1
}

resolve_worktree() {
    local repo_dir="$1"
    local expected_common actual_common

    if [ -n "${PLAN_MANAGER_WORKTREE:-}" ]; then
        if ! valid_worktree "$PLAN_MANAGER_WORKTREE"; then
            error "PLAN_MANAGER_WORKTREE is not a Git worktree root: $PLAN_MANAGER_WORKTREE"
            return 1
        fi
        expected_common="$(configured_common_dir "$repo_dir" 2>/dev/null || true)"
        if [ -z "$expected_common" ]; then
            error "Cannot verify PLAN_MANAGER_WORKTREE against $repo_dir"
            return 1
        fi
        actual_common="$(git_common_dir "$PLAN_MANAGER_WORKTREE")" || return 1
        if [ "$actual_common" != "$expected_common" ]; then
            error "PLAN_MANAGER_WORKTREE does not belong to the configured repository"
            return 1
        fi
        canonical_dir "$PLAN_MANAGER_WORKTREE"
        return
    fi

    if [ -d "$repo_dir/.bare" ]; then
        if [ "$(git --git-dir="$repo_dir/.bare" rev-parse --is-bare-repository 2>/dev/null || true)" != "true" ]; then
            error "$repo_dir/.bare is not a valid bare Git repository"
            return 1
        fi
        if ! valid_worktree "$repo_dir/main"; then
            error "The bare repository does not have a valid main worktree"
            return 1
        fi
        expected_common="$(canonical_dir "$repo_dir/.bare")"
        actual_common="$(git_common_dir "$repo_dir/main")" || return 1
        if [ "$actual_common" != "$expected_common" ]; then
            error "$repo_dir/main does not belong to $repo_dir/.bare"
            return 1
        fi
        canonical_dir "$repo_dir/main"
        return
    fi

    if valid_worktree "$repo_dir"; then
        canonical_dir "$repo_dir"
        return
    fi

    error "Cannot resolve a supported plan-manager checkout at $repo_dir"
    return 1
}

resolve_clone_url() {
    if [ -n "${PLAN_MANAGER_REPO_URL:-}" ]; then
        printf '%s\n' "$PLAN_MANAGER_REPO_URL"
        return
    fi
    local gh_user url
    gh_user="$(github_owner || true)"
    if [ -n "$gh_user" ]; then
        url="$(github_repo_url "$gh_user/plan-manager")"
        if [ "$gh_user" = "$PLAN_MANAGER_UPSTREAM_OWNER" ] || github_repo_accessible "$url"; then
            printf '%s\n' "$url"
            return
        fi
    fi
    printf 'https://github.com/%s/plan-manager.git\n' "$PLAN_MANAGER_UPSTREAM_OWNER"
}

resolve_ssh_host() {
    local host="$1"
    local resolved=""
    if command -v ssh >/dev/null 2>&1; then
        resolved="$(ssh -G "$host" 2>/dev/null | awk '$1 == "hostname" { print $2; exit }' || true)"
    fi
    resolved="${resolved:-$host}"
    if [ "$resolved" = "ssh.github.com" ]; then
        resolved="github.com"
    fi
    printf '%s\n' "$resolved"
}

normalize_remote_url() {
    local value="${1%.git}"
    local host path
    case "$value" in
        http://* | https://*)
            value="${value#*://}"
            printf '%s\n' "${value#*@}"
            return
            ;;
        ssh://*)
            value="${value#ssh://}"
            value="${value#*@}"
            host="${value%%/*}"
            host="${host%%:*}"
            path="${value#*/}"
            ;;
        *:*)
            value="${value#*@}"
            host="${value%%:*}"
            path="${value#*:}"
            ;;
        *)
            printf '%s\n' "$value"
            return
            ;;
    esac
    printf '%s/%s\n' "$(resolve_ssh_host "$host")" "$path"
}

validate_origin() {
    local worktree="$1"
    local expected_url="${2:-}"
    local actual_url rewritten_url

    actual_url="$(git -C "$worktree" remote get-url origin 2>/dev/null || true)"
    if [ -z "$expected_url" ]; then
        if [ -z "$actual_url" ]; then
            warning "The plan-manager checkout has no origin; cross-machine bootstrap remains unavailable."
        else
            info "No expected repository URL is configured; preserving origin $actual_url without fetching."
        fi
        return
    fi
    if [ -z "$actual_url" ]; then
        error "The plan-manager checkout has no origin, but $expected_url is configured."
        return 1
    fi
    rewritten_url="$(git -C "$worktree" ls-remote --get-url "$expected_url" 2>/dev/null || true)"
    if [ "$(normalize_remote_url "$actual_url")" != "$(normalize_remote_url "${rewritten_url:-$expected_url}")" ]; then
        error "Unexpected plan-manager origin."
        error "Expected: $expected_url"
        error "Actual:   $actual_url"
        return 1
    fi
}

update_clean_worktree() {
    local worktree="$1"
    local expected_url="$2"
    local upstream

    if [ -n "$(git -C "$worktree" status --porcelain --untracked-files=normal)" ]; then
        warning "$worktree has local changes; preserving it without fetching or updating."
        return
    fi
    if [ -z "$expected_url" ]; then
        info "$worktree has no configured origin; preserving it without fetching or updating."
        return 0
    fi
    upstream="$(git -C "$worktree" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
    if [ -z "$upstream" ]; then
        warning "$worktree has no upstream branch; preserving it without updating."
        return
    fi
    if ! github_git -C "$worktree" fetch --quiet origin; then
        error "Could not fetch the configured plan-manager origin."
        return 1
    fi
    if git -C "$worktree" merge-base --is-ancestor HEAD "$upstream"; then
        if [ "$(git -C "$worktree" rev-parse HEAD)" != "$(git -C "$worktree" rev-parse "$upstream")" ]; then
            git -C "$worktree" merge --ff-only "$upstream" --quiet
            success "Fast-forwarded $worktree"
        else
            info "$worktree is already up to date."
        fi
    elif git -C "$worktree" merge-base --is-ancestor "$upstream" HEAD; then
        info "$worktree is ahead of $upstream; preserving local commits."
    else
        warning "$worktree has diverged from $upstream; manual resolution is required."
    fi
}

bootstrap_plan_repo() {
    title "Bootstrapping plan-manager repository"

    local expected_url worktree clone_parent clone_tmp actual_url
    expected_url="${PLAN_MANAGER_REPO_URL:-}"

    if [ ! -e "$PLAN_REPO_DIR" ] && [ ! -L "$PLAN_REPO_DIR" ]; then
        if [ -z "$expected_url" ]; then
            expected_url="$(resolve_clone_url 2>/dev/null || true)"
        fi
        if [ -z "$expected_url" ]; then
            error "The plan-manager repository is missing at $PLAN_REPO_DIR."
            error "Set PLAN_MANAGER_REPO_URL or authenticate gh before retrying."
            return 1
        fi
        clone_parent="$(dirname "$PLAN_REPO_DIR")"
        mkdir -p "$clone_parent"
        clone_tmp="${PLAN_REPO_DIR}.clone-${$}"
        if [ -e "$clone_tmp" ] || [ -L "$clone_tmp" ]; then
            error "Temporary clone target already exists: $clone_tmp"
            return 1
        fi
        info "Cloning $expected_url"
        if ! github_clone "$expected_url" "$clone_tmp"; then
            rm -rf "$clone_tmp"
            error "Clone failed; no checkout was installed at $PLAN_REPO_DIR."
            return 1
        fi
        if ! mv "$clone_tmp" "$PLAN_REPO_DIR"; then
            rm -rf "$clone_tmp"
            error "Could not install the cloned repository at $PLAN_REPO_DIR."
            return 1
        fi
    elif [ ! -d "$PLAN_REPO_DIR" ]; then
        error "The plan-manager target exists but is not a directory: $PLAN_REPO_DIR"
        return 1
    fi

    worktree="$(resolve_worktree "$PLAN_REPO_DIR")" || return 1
    if [ -z "$expected_url" ]; then
        actual_url="$(git -C "$worktree" remote get-url origin 2>/dev/null || true)"
        if [ -n "$actual_url" ]; then
            expected_url="$(resolve_clone_url 2>/dev/null || true)"
        fi
    fi
    validate_origin "$worktree" "$expected_url" || return 1
    update_clean_worktree "$worktree" "$expected_url" || return 1
    PLAN_WORKTREE="$worktree"
    export PLAN_WORKTREE
    success "Resolved plan-manager worktree: $PLAN_WORKTREE"
}

install_plan_cli() {
    local worktree="${PLAN_WORKTREE:-}"
    local module="github.com/hacker1db/plan-manager/cli"
    local managed="$HOME/.local/lib/plan-manager"
    local stage identity version completion replacement link_stage

    [ -n "$worktree" ] || worktree="$(resolve_worktree "$PLAN_REPO_DIR")" || return 1
    title "Installing Go plan CLI from $worktree"
    command -v go >/dev/null 2>&1 || {
        error "Go is required to build plan-manager (see cli/go.mod for the required toolchain)."
        return 1
    }
    if [ ! -f "$worktree/cli/go.mod" ] || [ ! -f "$worktree/cli/cmd/plan/main.go" ]; then
        error "Missing Go CLI in $worktree; select a checkout containing cli/cmd/plan. The existing command was preserved."
        return 1
    fi
    if [ "$(awk '$1 == "module" { print $2; exit }' "$worktree/cli/go.mod")" != "$module" ] ||
        ! awk '$1 == "go" && $2 ~ /^[0-9]+\.[0-9]+/ { found=1 } END { exit !found }' "$worktree/cli/go.mod"; then
        error "Unexpected or incomplete Go module in $worktree/cli/go.mod."
        return 1
    fi
    mkdir -p "$managed" "$LOCAL_BIN" || return 1
    stage="$(mktemp -d "$managed/.stage.XXXXXX")" || return 1
    if ! (cd "$worktree/cli" && GOBIN="$stage" GOWORK=off GOFLAGS= go install -mod=readonly ./cmd/plan); then
        rm -rf "$stage"
        error "Go package build failed; the previous plan command was preserved. Check the toolchain requirement in cli/go.mod."
        return 1
    fi
    identity="$(go version -m "$stage/plan" 2>/dev/null)" || identity=""
    version="$("$stage/plan" --version 2>/dev/null)" || version=""
    completion="$("$stage/plan" completion zsh 2>/dev/null)" || completion=""
    if [ ! -x "$stage/plan" ] ||
        ! printf '%s\n' "$identity" | awk -v expected="$module" '$1 == "path" && $2 == expected "/cmd/plan" { path=1 } $1 == "mod" && $2 == expected { module=1 } END { exit !(path && module) }' ||
        [[ ! "$version" =~ [0-9]+\.[0-9]+\.[0-9]+ ]] ||
        [[ "$completion" != *"compdef"* ]]; then
        rm -rf "$stage"
        error "Staged plan failed Go identity, version, or Zsh completion validation; the previous command was preserved."
        return 1
    fi
    PLAN_CLI_CHANGED=0
    if ! cmp -s "$stage/plan" "$managed/plan"; then
        if [ -e "$managed/plan" ] || [ -L "$managed/plan" ]; then
            replacement="$(backup_path "$managed/plan")"
            cp -p "$managed/plan" "$replacement" || { rm -rf "$stage"; return 1; }
            info "Previous Go binary backed up to $replacement"
        fi
        mv -f "$stage/plan" "$managed/plan" || { rm -rf "$stage"; return 1; }
        PLAN_CLI_CHANGED=1
    fi
    rm -rf "$stage"
    if [ ! -L "$PLAN_LINK" ] || [ "$(readlink "$PLAN_LINK")" != "$managed/plan" ]; then
        if [ -d "$PLAN_LINK" ] && [ ! -L "$PLAN_LINK" ]; then
            error "$PLAN_LINK is a directory; refusing to replace it."
            return 1
        fi
        if [ -e "$PLAN_LINK" ] || [ -L "$PLAN_LINK" ]; then
            replacement="$(backup_path "$PLAN_LINK")"
            cp -Pp "$PLAN_LINK" "$replacement" || return 1
            warning "Backed up the previous plan command to $replacement"
        fi
        link_stage="$(mktemp -d "$LOCAL_BIN/.plan-link.XXXXXX")" || return 1
        ln -s "$managed/plan" "$link_stage/plan" && mv -f "$link_stage/plan" "$PLAN_LINK" || {
            rm -rf "$link_stage"
            return 1
        }
        rmdir "$link_stage"
        PLAN_CLI_CHANGED=1
    fi
    export PLAN_CLI_CHANGED
    export PATH="$LOCAL_BIN:$PATH"
    success "Installed Go plan $version: $PLAN_LINK -> $managed/plan (source: $worktree/cli)"
}

diagnose_plan_command() {
    local selected kind
    command -v zsh >/dev/null 2>&1 || { warning "Zsh is unavailable; cannot check fresh-shell plan resolution."; return 0; }
    kind="$(zsh -ic 'whence -w plan' 2>/dev/null | tail -n 1)"
    selected="$(zsh -ic 'whence -p plan' 2>/dev/null | tail -n 1)"
    if [ "$kind" != 'plan: command' ] || [ "$selected" != "$PLAN_LINK" ]; then
        warning "Fresh Zsh selects $kind at $selected; expected $PLAN_LINK. Inspect type -a plan for stale wrappers, aliases, or functions."
        return 1
    fi
    success "Fresh Zsh selects $PLAN_LINK. Existing shells: source ~/.zshrc; rehash."
}

link_managed_file() {
    local src="$1"
    local dest="$2"
    local label="$3"
    local replacement

    [ -f "$src" ] || {
        error "Missing managed source for $label: $src"
        return 1
    }
    if ! mkdir -p "$(dirname "$dest")"; then
        error "Could not create the destination directory for $label: $(dirname "$dest")"
        return 1
    fi
    if [ -e "$dest" ] && [ "$src" -ef "$dest" ]; then
        info "$label already resolves to its managed source."
        return
    fi
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        info "$label is already linked correctly."
        return
    fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        replacement="$(backup_path "$dest")"
        if ! mv "$dest" "$replacement"; then
            error "Could not back up unmanaged $label to $replacement"
            return 1
        fi
        warning "Backed up unmanaged $label to $replacement"
    fi
    if ! ln -s "$src" "$dest"; then
        error "Could not link $label at $dest"
        return 1
    fi
    success "Linked $label"
}

install_plan_instruction_links() {
    title "Installing plan-manager global instructions"
    link_managed_file \
        "$DOTFILES/global/AGENTS.md" \
        "$HOME/.copilot/copilot-instructions.md" \
        "Copilot global instructions" || return 1
    link_managed_file \
        "$DOTFILES/global/AGENTS.md" \
        "$HOME/.codex/AGENTS.md" \
        "Codex global instructions" || return 1
    link_managed_file \
        "$DOTFILES/global/AGENTS.md" \
        "$HOME/.config/opencode/AGENTS.md" \
        "OpenCode global instructions" || return 1
    if [ -s "$HOME/.codex/AGENTS.override.md" ]; then
        warning "$HOME/.codex/AGENTS.override.md is non-empty and shadows the managed plan policy."
        PLAN_CODEX_OVERRIDE_CONFLICT=1
        export PLAN_CODEX_OVERRIDE_CONFLICT
    fi
}

reconcile_codex_config() {
    title "Reconciling Codex plan-library access"
    local config="$HOME/.codex/config.toml"
    local output
    command -v node >/dev/null 2>&1 || { error "Node.js is required by the Codex config reconciler."; return 1; }
    output="$(node "$DOTFILES/install/reconcile-codex-config.mjs" "$config" "$PLAN_ROOT")" || {
        error "Could not reconcile $config."
        return 1
    }
    while IFS= read -r line; do
        [ -n "$line" ] && info "$line"
    done <<< "$output"
}

install_plan_launch_agent() {
    title "Installing plan-manager LaunchAgent"

    if [ "$(uname -s)" != "Darwin" ]; then
        warning "LaunchAgent is macOS-only; skipping plan-manager service on $(uname -s)."
        return 0
    fi

    local worktree="${PLAN_WORKTREE:-}"
    local template="$DOTFILES/launchd/com.plan-manager.serve.plist.template"
    local destination="$HOME/Library/LaunchAgents/com.plan-manager.serve.plist"
    local log_dir="$HOME/Library/Logs/plan-manager"
    local runtime_path render_state uid domain label cli_identity

    command -v node >/dev/null 2>&1 || { error "Node.js is required by the LaunchAgent renderer."; return 1; }

    [ -n "$worktree" ] || worktree="$(resolve_worktree "$PLAN_REPO_DIR")" || return 1
    command -v pandoc >/dev/null 2>&1 || {
        error "Pandoc is required by the local dashboard."
        return 1
    }
    mkdir -p "$(dirname "$destination")" "$log_dir"
    runtime_path="$LOCAL_BIN:$(dirname "$(command -v node)"):$(dirname "$(command -v pandoc)"):/usr/bin:/bin:/usr/sbin:/sbin"
    cli_identity="$(shasum -a 256 "$PLAN_LINK")" || return 1
    cli_identity="${cli_identity%% *}"
    [[ "$cli_identity" =~ ^[0-9a-f]{64}$ ]] || { error "Could not identify the installed plan binary."; return 1; }
    render_state="$(node "$DOTFILES/install/render-plan-launchagent.mjs" \
        "$template" "$destination" "$HOME" "$PLAN_LINK" "$worktree" "$PLAN_ROOT" "$runtime_path" "$cli_identity")" || {
        error "Could not render the plan-manager LaunchAgent."
        return 1
    }
    info "LaunchAgent $render_state"

    if [ "${PLAN_MANAGER_SKIP_LAUNCHCTL:-0}" = "1" ]; then
        info "Skipping launchctl reconciliation because PLAN_MANAGER_SKIP_LAUNCHCTL=1."
        return
    fi
    command -v launchctl >/dev/null 2>&1 || {
        error "launchctl is required to load the plan-manager service."
        return 1
    }
    uid="$(id -u)"
    domain="gui/$uid"
    label="$domain/com.plan-manager.serve"
    if [ "$render_state" = "changed" ] && launchctl print "$label" >/dev/null 2>&1; then
        if ! launchctl bootout "$label"; then
            error "Could not unload the previous plan-manager LaunchAgent."
            return 1
        fi
    fi
    if ! launchctl print "$label" >/dev/null 2>&1; then
        if ! launchctl bootstrap "$domain" "$destination"; then
            error "Could not load the plan-manager LaunchAgent."
            return 1
        fi
        success "Plan-manager LaunchAgent is loaded."
    else
        info "Plan-manager LaunchAgent is already loaded with unchanged configuration."
    fi
}

initialize_plan_library() {
    title "Initializing plan library"
    if [ ! -d "$PLAN_ROOT" ]; then
        warning "$PLAN_ROOT does not exist; it lives in the Second Brain vault. Sync the vault, then re-run the linker."
        return 0
    fi
    PLAN_HOME="$PLAN_ROOT" "$PLAN_LINK" init || return 1
}

verify_plan_service() {
    local pid executable expected
    command -v lsof >/dev/null 2>&1 || { error "lsof is required to verify the dashboard executable."; return 1; }
    expected="$(canonical_dir "$HOME/.local/lib/plan-manager")/plan" || return 1
    for pid in $(lsof -nP -iTCP:"${PLAN_PORT:-4173}" -sTCP:LISTEN -t 2>/dev/null | sort -u); do
        executable="$(lsof -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1)"
        if [ "$executable" != "$expected" ]; then
            error "Dashboard PID $pid runs $executable; expected $expected. Inspect the existing listener before restarting the service."
            return 1
        fi
        success "Dashboard PID $pid runs $executable."
        return 0
    done
    error "Cannot verify a dashboard listener on port ${PLAN_PORT:-4173}."
    return 1
}

check_plan_manager() {
    title "Checking plan-manager"
    [ -d "$PLAN_ROOT" ] || return 0
    PLAN_HOME="$PLAN_ROOT" "$PLAN_LINK" serve --json >/dev/null || return 1
    PLAN_HOME="$PLAN_ROOT" "$PLAN_LINK" doctor --json || return 1
    verify_plan_service || return 1
    diagnose_plan_command || return 1
}

run_plan_manager_install() {
    bootstrap_plan_repo || return 1
    install_plan_cli || return 1
    install_plan_instruction_links || return 1
    reconcile_codex_config || return 1
    initialize_plan_library || return 1
    install_plan_launch_agent || return 1
    check_plan_manager || return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run_plan_manager_install
fi
