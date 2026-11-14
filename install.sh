#!/usr/bin/env zsh
set -uo pipefail
ROOT="${0:A:h}"

if [[ ! -f "${0:A}" || ! -f "$ROOT/install/lib.zsh" ]]; then
    die() { print -u2 "$1"; exit 1 }
    url=https://github.com/hacker1db/Dotfiles.git
    repo="$HOME/Developer/dotfiles"
    if ! xcode-select -p &> /dev/null; then
        xcode-select --install
        die "Finish installing the Command Line Tools, then run this command again."
    fi
    if [[ ! -d "$repo/.bare" ]]; then
        mkdir -p "$repo" && git clone --bare "$url" "$repo/.bare" || die "Cloning $url failed."
    fi
    [[ "$(git --git-dir="$repo/.bare" config remote.origin.url)" == *[/:]hacker1db/Dotfiles(|.git) ]] \
        || die "$repo/.bare is not a clone of $url; move it aside and run this command again."
    [[ -f "$repo/.git" ]] || print "gitdir: ./.bare" > "$repo/.git"
    git --git-dir="$repo/.bare" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    if [[ ! -e "$repo/main" ]]; then
        git --git-dir="$repo/.bare" fetch origin || die "Fetching origin failed."
        git -C "$repo" worktree add main main || die "Creating the main worktree failed."
        git -C "$repo/main" branch --set-upstream-to=origin/main
    fi
    common="$(git -C "$repo/main" rev-parse --path-format=absolute --git-common-dir 2> /dev/null)"
    [[ -n "$common" && "${common:A}" == "${repo:A}/.bare" && -f "$repo/main/install.sh" ]] \
        || die "$repo/main is not a worktree of $repo/.bare; move it aside and run this command again."
    exec "$repo/main/install.sh" "${@:-all}"
fi

source "$ROOT/install/lib.zsh"

typeset -a steps=(tools link node dotnet osx theme browser tmux-plugins agent-profiles)

usage() { print -u2 "Usage: ${0:t} {all|${(j:|:)steps}|deferred|use} [args]"; exit 1 }

run_step() {
    local name="$1"; shift
    load_brew_env || true
    zsh "$ROOT/install/${name}.zsh" "$@"
}

[[ $# -ge 1 ]] || usage
cmd="$1"; shift

if [[ "$cmd" == all ]]; then
    title "Running full install"
    export DOTFILES_DEFER_PROMPTS=1
    typeset -a failed=()
    typeset step rc
    for step in $steps; do
        info "Executing $step"
        rc=0
        run_step "$step" || rc=$?
        if [[ "$rc" -eq 0 ]]; then
            continue
        elif [[ "$step" == tools ]]; then
            error "tools failed; the remaining steps need Homebrew, stopping"
            exit 1
        elif [[ "$step" == agent-profiles && "$rc" -eq 2 ]]; then
            warning "Agent profile setup is incomplete; see the messages above."
        else
            error "$step failed; continuing"
            failed+=("$step")
        fi
    done
    info "Executing deferred installs and shell setup"
    run_step tools deferred || failed+=(deferred)
    print
    [[ "${#failed}" -eq 0 ]] || { error "Finished with failures: $failed"; exit 1 }
    success "All tasks complete"
    exit 0
fi

case "$cmd" in
    use)
        [[ $# -le 1 ]] || usage
        exec zsh "$ROOT/bin/dotfiles-use" "${1:-$ROOT}"
        ;;
    deferred) run_step tools deferred "$@" ;;
    ${(~j:|:)steps}) run_step "$cmd" "$@" ;;
    *) usage ;;
esac
rc=$?
[[ "$rc" -eq 0 ]] || exit "$rc"
print
success "Done."
