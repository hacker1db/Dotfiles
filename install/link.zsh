#!/usr/bin/env zsh
set -uo pipefail
source "${0:A:h}/lib.zsh"

LINK_FAILURE=0

title "Creating symlinks"
typeset file config entry destination backup
for file in "$DOTFILES"/*.symlink(N) "$DOTFILES"/*/*.symlink(N) "$DOTFILES"/*/*/*.symlink(N); do
    link_file "$file" "$HOME/.${${file:t}%.symlink}"
done

title "Installing to ~/.config"
mkdir -p "$HOME/.config"
for config in "$DOTFILES"/config/*(N); do
    link_file "$config" "$HOME/.config/${config:t}"
done

title "Linking agent instructions"
typeset instructions="$DOTFILES/global/AGENTS.md"
[[ -f "$instructions" ]] || { error "Missing instruction source: $instructions"; exit 1 }
for destination in "$HOME/.codex/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"; do
    if [[ -e "$destination" && "$instructions" -ef "$destination" ]]; then
        print "Instruction file already linked: $destination"
        continue
    elif [[ -d "$destination" && ! -L "$destination" ]]; then
        error "Instruction destination is a directory: $destination"
        LINK_FAILURE=1
        continue
    fi
    mkdir -p "${destination:h}"
    if [[ -e "$destination" || -L "$destination" ]]; then
        backup="$(backup_path "$destination")"
        mv "$destination" "$backup"
        print "Preserved existing instruction file: $backup"
    fi
    ln -s "$instructions" "$destination"
    print "Linked $destination -> $instructions"
done

title "Linking Claude Code MCP servers"
link_file "$DOTFILES/claude/mcp.json" "$HOME/.mcp.json"

title "Installing SSH config"
if [[ -e "$DOTFILES/ssh/config" ]]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    chmod 600 "$DOTFILES/ssh/config"
    link_file "$DOTFILES/ssh/config" "$HOME/.ssh/config"
fi

github_ssh_preflight >&2 || true

title "Ensuring the clitools checkout"
GH_USER="$(github_owner 2>/dev/null || true)"
CLITOOLS_DIR="$(clitools_dir)"
if [[ -z "${CLITOOLS_REPO_URL:-}" && -n "$GH_USER" ]]; then
    CLITOOLS_REPO_URL="$(github_repo_url "$GH_USER/clitools")"
fi
if [[ -e "$CLITOOLS_DIR/.git" ]]; then
    print "Using existing clitools checkout at $CLITOOLS_DIR"
    update_clean_checkout "$CLITOOLS_DIR"
elif [[ -z "${CLITOOLS_REPO_URL:-}" ]]; then
    warning "GitHub owner could not be determined (set DOTFILES_GITHUB_OWNER); skipping clitools clone"
elif ! github_repo_accessible "$CLITOOLS_REPO_URL"; then
    print "clitools is private or missing at $CLITOOLS_REPO_URL; skipping it (set CLITOOLS_REPO_URL to use your own)"
else
    print "Cloning clitools repo to $CLITOOLS_DIR"
    mkdir -p "${CLITOOLS_DIR:h}"
    github_clone "$CLITOOLS_REPO_URL" "$CLITOOLS_DIR" || print "Failed to clone clitools; continuing without it"
fi

title "Ensuring ~/.gitconfig-local link"
LOCAL_FILE="$HOME/.gitconfig-local"
SOURCE_CANDIDATE=""
typeset f
for f in gitconfig-local .gitconfig-local gitconfig.local; do
    [[ -f "$CLITOOLS_DIR/$f" ]] && SOURCE_CANDIDATE="$CLITOOLS_DIR/$f" && break
done
if [[ -n "$SOURCE_CANDIDATE" ]]; then
    if [[ ! -L "$LOCAL_FILE" && -e "$LOCAL_FILE" ]]; then
        backup="$(backup_path "$LOCAL_FILE")"
        mv "$LOCAL_FILE" "$backup" || exit 1
        print "Preserved existing $LOCAL_FILE: $backup"
    fi
    link_file "$SOURCE_CANDIDATE" "$LOCAL_FILE"
elif [[ ! -e "$LOCAL_FILE" ]]; then
    touch "$LOCAL_FILE"
    print "Created empty $LOCAL_FILE (no clitools source found)"
else
    print "$LOCAL_FILE exists (no clitools source found); leaving as-is."
fi

title "Configuring Git identity"
PROFILE_DIR="$DOTFILES/git/profiles"
profile="${DOTFILES_GIT_PROFILE:-}"
interactive=0
[[ "${DOTFILES_NONINTERACTIVE:-0}" != 1 && -t 0 ]] && interactive=1
if [[ -z "$profile" && "$interactive" == 1 ]]; then
    typeset -a profiles=("$PROFILE_DIR"/*/gitconfig(N:h:t))
    if [[ "${#profiles}" -gt 0 ]]; then
        print "Available Git account profiles: $profiles"
        read -r "profile?Profile to enable (blank for none): "
    fi
fi
if [[ -n "$profile" ]]; then
    [[ -f "$PROFILE_DIR/$profile/gitconfig" ]] || { error "Unknown Git profile: $profile"; exit 1 }
    link_file "$PROFILE_DIR/$profile/gitconfig" "$HOME/.gitconfig-accounts"
    if [[ -f "$PROFILE_DIR/$profile/ssh_config" ]]; then
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        link_file "$PROFILE_DIR/$profile/ssh_config" "$HOME/.ssh/config-accounts"
    fi
    git config -f "$LOCAL_FILE" --unset-all user.signingkey 2>/dev/null || true
fi
if [[ "$interactive" == 1 ]]; then
    typeset key value
    for key in user.name user.email; do
        [[ -n "$(git config --get "$key")" ]] && continue
        read -r "value?Git $key: "
        [[ -n "$value" ]] && git config -f "$LOCAL_FILE" "$key" "$value"
    done
fi

title "Checking Codex plan-library access"
PLAN_ROOT="${PLAN_HOME:-$HOME/notes/SecondBrain/4.Resources/plans}"
CODEX_CONFIG="$HOME/.codex/config.toml"
if [[ ! -f "$CODEX_CONFIG" ]]; then
    mkdir -p "${CODEX_CONFIG:h}"
    printf '[sandbox_workspace_write]\nwritable_roots = ["%s"]\n' "$PLAN_ROOT" > "$CODEX_CONFIG"
    print "Created $CODEX_CONFIG with the plan library writable"
else
    node "$DOTFILES/install/check-codex-writable-root.mjs" "$CODEX_CONFIG" "$PLAN_ROOT"
    writable_root_status=$?
    if [[ "$writable_root_status" -eq 0 ]]; then
        print "Codex already allows writes to $PLAN_ROOT"
    elif [[ "$writable_root_status" -eq 2 ]]; then
        warning "Could not validate writable_roots in $CODEX_CONFIG"
        LINK_FAILURE=1
    elif grep -q '^[[:space:]]*\[sandbox_workspace_write\][[:space:]]*\(#.*\)\?$' "$CODEX_CONFIG"; then
        warning "Add \"$PLAN_ROOT\" to writable_roots under [sandbox_workspace_write] in $CODEX_CONFIG"
        LINK_FAILURE=1
    else
        printf '\n[sandbox_workspace_write]\nwritable_roots = ["%s"]\n' "$PLAN_ROOT" >> "$CODEX_CONFIG"
        print "Added the plan library to writable_roots in $CODEX_CONFIG"
    fi
fi

title "Installing the Go plan CLI"
PLAN_REPO_DIR="${PLAN_MANAGER_REPO_DIR:-}"
if [[ -z "$PLAN_REPO_DIR" && -n "$GH_USER" ]]; then
    PLAN_REPO_DIR="$(find_github_checkout "$GH_USER/plan-manager" || true)"
fi
PLAN_REPO_DIR="${PLAN_REPO_DIR:-$HOME/Developer/plan-manager}"
if [[ ! -d "$PLAN_REPO_DIR" ]]; then
    PLAN_URL="${PLAN_MANAGER_REPO_URL:-}"
    if [[ -z "$PLAN_URL" && -n "$GH_USER" ]]; then
        PLAN_URL="$(github_repo_url "$GH_USER/plan-manager")"
        [[ "$GH_USER" == hacker1db ]] || github_repo_accessible "$PLAN_URL" || PLAN_URL=""
    fi
    PLAN_URL="${PLAN_URL:-https://github.com/hacker1db/plan-manager.git}"
    print "Cloning $PLAN_URL"
    mkdir -p "${PLAN_REPO_DIR:h}"
    github_clone "$PLAN_URL" "$PLAN_REPO_DIR" || { error "Failed to clone plan-manager"; LINK_FAILURE=1 }
fi
PLAN_WORKTREE="$PLAN_REPO_DIR"
[[ -d "$PLAN_REPO_DIR/.bare" ]] && PLAN_WORKTREE="$PLAN_REPO_DIR/main"
if [[ ! -e "$PLAN_WORKTREE/.git" ]]; then
    warning "No plan-manager checkout at $PLAN_WORKTREE; skipping the plan CLI install."
    LINK_FAILURE=1
elif ! command -v go >/dev/null 2>&1; then
    error "Go is required to build the plan CLI (see cli/go.mod)."
    LINK_FAILURE=1
elif [[ ! -f "$PLAN_WORKTREE/cli/go.mod" ]]; then
    error "Missing Go CLI in $PLAN_WORKTREE; expected cli/cmd/plan."
    LINK_FAILURE=1
else
    update_clean_checkout "$PLAN_WORKTREE"
    mkdir -p "$HOME/.local/bin"
    if (cd "$PLAN_WORKTREE/cli" && GOBIN="$HOME/.local/bin" GOWORK=off GOFLAGS= go install -mod=readonly ./cmd/plan); then
        success "Installed $HOME/.local/bin/plan from $PLAN_WORKTREE/cli"
    else
        error "go install failed for the plan CLI; the previous command was preserved."
        LINK_FAILURE=1
    fi
fi

[[ "$LINK_FAILURE" -eq 0 ]] || { error "Dotfiles linking needs attention; see the diagnostics above."; exit 1 }
success "Linking complete"
