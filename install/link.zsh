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

title "Linking Herdr app config"
HERDR_HOME="$HOME/.config/herdr-app"
mkdir -p "$HERDR_HOME"/{layouts,themes,mods}
typeset herdr_src
for herdr_src in "$DOTFILES/herdr/keys.json" "$DOTFILES"/herdr/{layouts,themes}/*.json(N) "$DOTFILES"/herdr/mods/*(N/); do
    destination="$HERDR_HOME/${herdr_src#$DOTFILES/herdr/}"
    if [[ -e "$destination" && ! -L "$destination" ]]; then
        backup="$(backup_path "$destination")"
        mv "$destination" "$backup" || { LINK_FAILURE=1; continue }
        print "Preserved existing Herdr file: $backup"
    fi
    link_file "$herdr_src" "$destination"
done
if command -v herdr-app >/dev/null 2>&1 && herdr-app status >/dev/null 2>&1; then
    herdr-app do layout.switch --name dotfiles >/dev/null 2>&1 && print "Switched Herdr to the dotfiles layout"
fi

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

title "Linking agent hooks"
typeset -A agent_hooks=(
    "$DOTFILES/codex/hooks.json" "$HOME/.codex/hooks.json"
    "$DOTFILES/copilot/hooks/rtk-rewrite.json" "$HOME/.copilot/hooks/rtk-rewrite.json"
)
typeset hook_src
for hook_src destination in "${(@kv)agent_hooks}"; do
    if [[ -L "$destination" && "$(readlink "$destination")" == "$hook_src" ]]; then
        print "Hook file already linked: $destination"
        continue
    fi
    mkdir -p "${destination:h}"
    if [[ -e "$destination" && ! -L "$destination" ]]; then
        backup="$(backup_path "$destination")"
        mv "$destination" "$backup"
        print "Preserved existing hook file: $backup"
    fi
    ln -sfn "$hook_src" "$destination"
    print "Linked $destination -> $hook_src"
done

title "Linking Git templates"
link_file "$DOTFILES/git/templates" "$HOME/.git-templates"

title "Refreshing Git hook dispatchers in existing repositories"
typeset dispatcher="$DOTFILES/git/templates/hooks/run-hooks.sh" hook_root hook_file
typeset -i hooks_refreshed=0
for hook_root in ${(s.:.)${DOTFILES_HOOK_ROOTS:-$HOME/Developer}}; do
    [[ -d "$hook_root" ]] || continue
    while IFS= read -r hook_file; do
        grep -qF 'Executing $hook_type hook(s)' "$hook_file" 2>/dev/null || continue
        cmp -s "$dispatcher" "$hook_file" && continue
        if cp "$dispatcher" "$hook_file"; then
            hooks_refreshed+=1
        else
            warning "Could not refresh $hook_file"
        fi
    done < <(find "$hook_root" -maxdepth 6 \( -name node_modules -o -name .terraform \) -prune \
        -o -type f \( -path '*/.git/hooks/*' -o -path '*/.bare/hooks/*' \) -print 2>/dev/null)
done
print "Refreshed $hooks_refreshed stale hook dispatcher copies"

title "Linking Claude Code MCP servers"
link_file "$DOTFILES/claude/mcp.json" "$HOME/.mcp.json"

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

title "Ensuring a machine-owned ~/.gitconfig-local"
LOCAL_FILE="$HOME/.gitconfig-local"
if [[ -L "$LOCAL_FILE" ]]; then
    if [[ -f "${LOCAL_FILE:A}" ]]; then
        cp "${LOCAL_FILE:A}" "$LOCAL_FILE.tmp" && mv -f "$LOCAL_FILE.tmp" "$LOCAL_FILE" || exit 1
        print "Replaced the $LOCAL_FILE link with a machine-owned copy; review its identity below"
    else
        rm "$LOCAL_FILE" && touch "$LOCAL_FILE" || exit 1
        print "Replaced a dangling $LOCAL_FILE link with an empty file"
    fi
elif [[ ! -e "$LOCAL_FILE" ]]; then
    touch "$LOCAL_FILE"
    print "Created empty $LOCAL_FILE"
else
    print "$LOCAL_FILE is machine-owned; leaving as-is."
fi

title "Configuring Git identity in $LOCAL_FILE"
typeset key label value current
typeset -a git_prompts=(
    user.name "Git user name for commits"
    user.email "Git email address for commits"
    github.user "GitHub username (the one account this machine uses)"
    user.signingkey "SSH signing public key from your password manager (blank to skip)"
    gpg.ssh.program "SSH signing program (blank for ssh-keygen)"
)
if [[ "${DOTFILES_NONINTERACTIVE:-0}" != 1 && -t 0 ]]; then
    for key label in $git_prompts; do
        current="$(git config --get "$key" 2>/dev/null)"
        value=""
        read -r "value?$label [$current]: "
        value="${value:-$current}"
        [[ -z "$value" ]] && continue
        [[ "$key" == user.signingkey && "$value" == ssh-* ]] && value="key::$value"
        git config -f "$LOCAL_FILE" "$key" "$value"
    done
    for key in user.name user.email github.user; do
        [[ -n "$(git config --get "$key")" ]] || warning "Git $key is not set; re-run '${DOTFILES}/install.sh link' to set it"
    done
else
    print "Non-interactive run; leaving $LOCAL_FILE as-is."
fi
typeset signing_key="$(git config --get user.signingkey)" signers signer_email
if [[ -n "$signing_key" ]]; then
    for key in commit.gpgsign tag.gpgsign; do
        [[ -n "$(git config --get "$key")" ]] || git config -f "$LOCAL_FILE" "$key" true
    done
    signers="$(git config --get gpg.ssh.allowedSignersFile)"
    if [[ -z "$signers" ]]; then
        signers="~/.ssh/allowed_signers"
        git config -f "$LOCAL_FILE" gpg.ssh.allowedSignersFile "$signers"
    fi
    signers="${signers/#\~/$HOME}"
    signer_email="$(git config --get user.email)"
    signing_key="${signing_key#key::}"
    if [[ -n "$signer_email" ]] && ! grep -qF "$signing_key" "$signers" 2>/dev/null; then
        mkdir -p "${signers:h}"
        print -r -- "$signer_email $signing_key" >> "$signers"
        print "Trusted $signer_email's signing key in $signers"
    fi
fi

title "Configuring the 1Password SSH agent"
OP_AGENT_TOML="$HOME/.config/1Password/ssh/agent.toml"
typeset op_item op_vault op_current
if [[ -L "$HOME/.config/1Password" || -L "${OP_AGENT_TOML:h}" || -L "$OP_AGENT_TOML" ]]; then
    warning "$OP_AGENT_TOML is linked into a checkout; make it machine-owned with 'fleet op-agent -item <item> -vault <vault>' from fleet-manager"
elif [[ "${DOTFILES_NONINTERACTIVE:-0}" != 1 && -t 0 ]]; then
    op_current=("${(@f)$(op_agent_first_key "$OP_AGENT_TOML")}")
    read -r "op_item?1Password item name of this machine's GitHub SSH key (blank to skip) [${op_current[1]:-}]: "
    op_item="${op_item:-${op_current[1]:-}}"
    if [[ -n "$op_item" ]]; then
        read -r "op_vault?1Password vault holding \"$op_item\" [${op_current[2]:-}]: "
        op_vault="${op_vault:-${op_current[2]:-}}"
    fi
    if [[ -z "$op_item" ]]; then
        print "No GitHub key chosen; leaving $OP_AGENT_TOML as-is."
    elif [[ -z "$op_vault" || "$op_item$op_vault" == *[\"\\]* ]]; then
        warning "Skipped $OP_AGENT_TOML: give a vault, and no quotes or backslashes in either name"
    elif op_agent_put_first "$OP_AGENT_TOML" "$op_item" "$op_vault"; then
        print "Listed \"$op_item\" from vault \"$op_vault\" first in $OP_AGENT_TOML"
    else
        warning "Could not update $OP_AGENT_TOML"
    fi
else
    print "Non-interactive run; leaving $OP_AGENT_TOML as-is."
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
        github_repo_accessible "$PLAN_URL" || PLAN_URL=""
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

title "Configuring T3 Code"
if [[ -d "$HOME/.t3" ]]; then
    T3_USERDATA="$HOME/.t3/userdata"
    mkdir -p "$T3_USERDATA"
    for file in client-settings.json keybindings.json; do
        destination="$T3_USERDATA/$file"
        if [[ -e "$destination" && ! -L "$destination" ]]; then
            backup="$(backup_path "$destination")"
            mv "$destination" "$backup" && print "Backup: $backup"
        fi
        link_file "$DOTFILES/config/t3code/$file" "$destination"
    done
    T3_STATUS=0
    python3 "$DOTFILES/bin/t3-config" providers --dotfiles-root "$DOTFILES" || T3_STATUS=$?
    case "$T3_STATUS" in
        0) ;;
        2) warning "Some T3 provider profiles are disabled until provisioned; see the diagnostics above." ;;
        *) error "T3 provider configuration failed."; LINK_FAILURE=1 ;;
    esac
else
    info "Skipping T3 Code; ~/.t3 not found."
fi

[[ "$LINK_FAILURE" -eq 0 ]] || { error "Dotfiles linking needs attention; see the diagnostics above."; exit 1 }
success "Linking complete"
