#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -euo pipefail
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd -P)"
source "$DOTFILES/install/lib/log.sh"
source "$DOTFILES/install/lib/env.sh"

PLAN_REPO_DIR="${PLAN_MANAGER_REPO_DIR:-$HOME/Developer/plan-manager}"
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
    local gh_user
    gh_user="$(github_owner || true)"
    [ -n "$gh_user" ] || return 1
    github_repo_url "$gh_user/plan-manager"
}

normalize_remote_url() {
    local value="$1"
    value="${value#ssh://}"
    value="${value/git@github.com:/github.com/}"
    value="${value/https:\/\/github.com\//github.com/}"
    value="${value/http:\/\/github.com\//github.com/}"
    value="${value%.git}"
    printf '%s\n' "$value"
}

validate_origin() {
    local worktree="$1"
    local expected_url="${2:-}"
    local actual_url

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
    if [ "$(normalize_remote_url "$actual_url")" != "$(normalize_remote_url "$expected_url")" ]; then
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
    local major bin_path version replacement

    [ -n "$worktree" ] || worktree="$(resolve_worktree "$PLAN_REPO_DIR")" || return 1
    title "Installing plan CLI"

    command -v node >/dev/null 2>&1 || {
        error "Node.js is required to install plan-manager."
        return 1
    }
    major="$(node -p 'Number(process.versions.node.split(".")[0])')"
    if [ "$major" -lt 20 ]; then
        error "Node.js 20 or newer is required; found $(node --version)."
        return 1
    fi
    command -v pnpm >/dev/null 2>&1 || {
        error "pnpm is required to install plan-manager."
        return 1
    }
    [ -f "$worktree/package.json" ] || {
        error "Missing package.json in $worktree."
        return 1
    }
    [ -f "$worktree/pnpm-lock.yaml" ] || {
        error "Missing pnpm-lock.yaml in $worktree."
        return 1
    }

    if ! pnpm --dir "$worktree" install --frozen-lockfile; then
        error "Frozen dependency installation failed; the existing CLI link was not changed."
        return 1
    fi
    if ! pnpm --dir "$worktree" build; then
        error "TypeScript build failed; the existing CLI link was not changed."
        return 1
    fi

    bin_path="$worktree/bin/plan"
    if [ ! -x "$bin_path" ]; then
        error "$bin_path is missing or not executable; the existing CLI link was not changed."
        return 1
    fi
    version="$("$bin_path" --version 2>/dev/null || true)"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        error "$bin_path failed its version check; the existing CLI link was not changed."
        return 1
    fi

    mkdir -p "$LOCAL_BIN"
    if [ -L "$PLAN_LINK" ] && [ "$(readlink "$PLAN_LINK")" = "$bin_path" ]; then
        info "$PLAN_LINK already points to $bin_path."
    else
        if [ -e "$PLAN_LINK" ] || [ -L "$PLAN_LINK" ]; then
            replacement="$(backup_path "$PLAN_LINK")"
            mv "$PLAN_LINK" "$replacement"
            warning "Backed up the previous plan command to $replacement"
        fi
        ln -s "$bin_path" "$PLAN_LINK"
        success "Linked ~/.local/bin/plan to $bin_path"
    fi
    export PATH="$LOCAL_BIN:$PATH"
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
        "$DOTFILES/claude/commands/plans.md" \
        "$HOME/.claude/commands/plans.md" \
        "Claude plans command" || return 1
    link_managed_file \
        "$DOTFILES/global/AGENTS.md" \
        "$HOME/.config/opencode/AGENTS.md" \
        "OpenCode global instructions" || return 1
    link_managed_file \
        "$DOTFILES/config/opencode/command/plans.md" \
        "$HOME/.config/opencode/command/plans.md" \
        "OpenCode plans command" || return 1
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
    local runtime_path render_state uid domain label

    [ -n "$worktree" ] || worktree="$(resolve_worktree "$PLAN_REPO_DIR")" || return 1
    command -v pandoc >/dev/null 2>&1 || {
        error "Pandoc is required by the local dashboard."
        return 1
    }
    mkdir -p "$(dirname "$destination")" "$log_dir"
    runtime_path="$LOCAL_BIN:$(dirname "$(command -v node)"):$(dirname "$(command -v pandoc)"):/usr/bin:/bin:/usr/sbin:/sbin"
    render_state="$(node "$DOTFILES/install/render-plan-launchagent.mjs" \
        "$template" "$destination" "$HOME" "$PLAN_LINK" "$worktree" "$PLAN_ROOT" "$runtime_path")" || {
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

check_plan_manager() {
    title "Checking plan-manager"
    [ -d "$PLAN_ROOT" ] || return 0
    PLAN_HOME="$PLAN_ROOT" "$PLAN_LINK" serve --json >/dev/null || return 1
    PLAN_HOME="$PLAN_ROOT" "$PLAN_LINK" doctor --json || return 1
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
