#!/usr/bin/env zsh
# Shared helpers sourced by install.sh and the install/*.zsh steps.

DOTFILES="${0:A:h:h}"

title() { print "\n\e[1;35m$1\e[0m\n\e[1;38;5;243m==============================\e[0m" }
info() { print "\e[1;34mInfo:\e[0m $1" }
warning() { print "\e[1;33mWarning:\e[0m $1" }
error() { print "\e[1;31mError:\e[0m $1" }
success() { print "\e[1;32m$1\e[0m" }

load_brew_env() {
    command -v brew >/dev/null 2>&1 && return 0
    local candidate
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [[ -x "$candidate" ]] && eval "$("$candidate" shellenv)" && return 0
    done
    return 1
}

deferred_installs_file() { print "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/deferred-installs" }

link_file() {
    local src="$1" dest="$2"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        return 0
    elif [[ -L "$dest" || ! -e "$dest" ]]; then
        ln -sfn "$src" "$dest"
        print "Linked $dest -> $src"
    else
        print "$dest exists and is not a symlink; skipping."
    fi
}

backup_path() {
    local candidate="$1.backup.$(date +%Y%m%d%H%M%S)" n=0
    while [[ -e "$candidate" || -L "$candidate" ]]; do
        candidate="$1.backup.$(date +%Y%m%d%H%M%S).$((++n))"
    done
    print "$candidate"
}

find_github_checkout() {
    local slug="${(L)1}" dir url
    for dir in "$HOME/Developer/${slug#*/}" "$HOME"/Developer/*/"${slug#*/}"(N); do
        [[ -d "$dir" ]] || continue
        url="$(git -C "$dir" config --get remote.origin.url 2>/dev/null)" || continue
        [[ "${(L)url}" == *"github.com"[:/]"$slug"(|.git) ]] && { print "$dir"; return 0 }
    done
    return 1
}

github_ssh_preflight() {
    if [[ -n "${GITHUB_SSH_OK:-}" ]]; then
        [[ "$GITHUB_SSH_OK" == 1 ]]; return
    fi
    local output
    output="$(ssh -T -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new git@github.com 2>&1 || true)"
    if [[ "$output" == *"successfully authenticated"* ]]; then
        export GITHUB_SSH_OK=1
        return 0
    fi
    export GITHUB_SSH_OK=0
    warning "GitHub SSH authentication is not available; GitHub clones will use HTTPS (gh supplies credentials when logged in)."
    print -u2 "  ssh said: $(print -r -- "$output" | tail -n 1)"
    return 1
}

github_repo_url() {
    github_ssh_preflight >&2 && print "git@github.com:$1.git" || print "https://github.com/$1.git"
}

github_git() {
    export GIT_TERMINAL_PROMPT=0
    if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
        git "$@"
    elif github_ssh_preflight >/dev/null 2>&1; then
        git -c credential.helper= -c 'credential.helper=!gh auth git-credential' "$@"
    else
        git -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
            -c url.https://github.com/.insteadOf=git@github.com: "$@"
    fi
}

github_repo_accessible() { github_git ls-remote --exit-code "$1" HEAD >/dev/null 2>&1 }

github_clone() { github_git clone "$@" }

github_owner() {
    if [[ -n "${DOTFILES_GITHUB_OWNER:-}" ]]; then
        print "$DOTFILES_GITHUB_OWNER"
        return
    fi
    local owner
    owner="$(git -C "$DOTFILES" remote get-url origin 2>/dev/null |
        sed -nE 's#^(git@github\.com:|ssh://git@github\.com/|https?://github\.com/)([^/]+)/.*#\2#p')"
    [[ -n "$owner" ]] || return 1
    print "$owner"
}

clitools_dir() {
    local owner found
    if [[ -n "${CLITOOLS_DIR:-}" ]]; then
        print "$CLITOOLS_DIR"
    elif owner="$(github_owner 2>/dev/null)" && found="$(find_github_checkout "$owner/clitools")"; then
        [[ -d "$found/.bare" ]] && print "$found/main" || print "$found"
    else
        print "$HOME/Developer/clitools/main"
    fi
}

update_clean_checkout() {
    local dir="$1"
    if [[ -n "$(git -C "$dir" status --porcelain --untracked-files=normal 2>/dev/null)" ]]; then
        warning "$dir has local changes; preserving it without fetching or updating."
    else
        github_git -C "$dir" fetch --quiet && git -C "$dir" merge --ff-only --quiet '@{u}' 2>/dev/null ||
            print "Could not update ${dir:t}; using existing copy"
    fi
}
