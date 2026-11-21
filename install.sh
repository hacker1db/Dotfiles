#!/usr/bin/env zsh
if [ -z "${ZSH_VERSION:-}" ]; then
    if [ "$(uname -s)" = Linux ]; then
        missing=
        for cmd in zsh git curl make gcc file ps; do
            command -v "$cmd" > /dev/null 2>&1 || missing=1
        done
        if [ -n "$missing" ]; then
            if [ "$(id -u)" -eq 0 ]; then sudo=; else sudo=sudo; fi
            if command -v apt-get > /dev/null 2>&1; then
                $sudo apt-get update && $sudo apt-get install -y zsh git curl build-essential procps file
            elif command -v dnf > /dev/null 2>&1; then
                $sudo dnf install -y zsh git curl gcc make procps-ng file
            elif command -v pacman > /dev/null 2>&1; then
                $sudo pacman -Sy --needed --noconfirm zsh git curl base-devel procps-ng file
            elif command -v zypper > /dev/null 2>&1; then
                $sudo zypper --non-interactive install zsh git curl gcc make procps file
            else
                echo "Install zsh, git, curl, a C compiler, make, procps, and file, then run this command again." >&2
                exit 1
            fi || { echo "Installing prerequisites failed." >&2; exit 1; }
        fi
    fi
    command -v zsh > /dev/null 2>&1 || { echo "Install zsh, then run this command again." >&2; exit 1; }
    case "$0" in
        *install.sh) [ -f "$0" ] && exec zsh "$0" "$@" ;;
    esac
    exec zsh -c "$(curl -fsSL https://raw.githubusercontent.com/hacker1db/Dotfiles/main/install.sh)" zsh "$@"
fi
set -uo pipefail
ROOT="${0:A:h}"

if [[ ! -f "${0:A}" || ! -f "$ROOT/install/lib.zsh" ]]; then
    die() { print -u2 "$1"; exit 1 }
    url=https://github.com/hacker1db/Dotfiles.git
    repo="$HOME/Developer/dotfiles"
    if [[ "$OSTYPE" == darwin* ]]; then
        if ! xcode-select -p &> /dev/null; then
            xcode-select --install
            die "Finish installing the Command Line Tools, then run this command again."
        fi
    elif ! command -v git &> /dev/null; then
        die "Install git, then run this command again."
    fi
    origin_re='^(git@github\.com:|ssh://git@github\.com/|https://github\.com/|git@github-[A-Za-z0-9._-]+:)hacker1db/Dotfiles(\.git)?$'
    # Older machines use a bare clone with a main/ worktree; keep running from it.
    if [[ -d "$repo/.bare" ]]; then
        [[ "$(git --git-dir="$repo/.bare" config remote.origin.url)" =~ $origin_re && -f "$repo/main/install.sh" ]] \
            || die "$repo/.bare is not a clone of $url with a main/ worktree; move it aside and run this command again."
        exec "$repo/main/install.sh" "${@:-all}"
    fi
    if [[ ! -d "$repo/.git" ]]; then
        [[ ! -e "$repo" || -z "$(ls -A "$repo")" ]] \
            || die "$repo exists and is not a clone of $url; move it aside and run this command again."
        git clone "$url" "$repo" || die "Cloning $url failed."
    fi
    [[ "$(git -C "$repo" config remote.origin.url)" =~ $origin_re && -f "$repo/install.sh" ]] \
        || die "$repo is not a clone of $url; move it aside and run this command again."
    exec "$repo/install.sh" "${@:-all}"
fi

source "$ROOT/install/lib.zsh"

typeset -a steps=(tools link node dotnet osx theme browser tmux-plugins)

usage() { print -u2 "Usage: ${0:t} {all|${(j:|:)steps}|deferred|use} [args]"; exit 1 }

restart_shell() {
    [[ -t 0 && -t 1 && "${DOTFILES_NONINTERACTIVE:-0}" != 1 ]] || return 0
    info "Starting a fresh shell"
    unset DOTFILES
    exec zsh -i
}

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
        elif [[ "$step" == link && "$rc" -eq 2 ]]; then
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
    restart_shell
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
[[ "$cmd" == link ]] && restart_shell
exit 0
