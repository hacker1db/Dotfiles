#!/usr/bin/env zsh
set -uo pipefail
ROOT="${0:A:h}"
source "$ROOT/install/lib.zsh"

typeset -a steps=(tools link node dotnet osx theme browser tmux-plugins claude-profiles)

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
        elif [[ "$step" == claude-profiles && "$rc" -eq 2 ]]; then
            warning "Claude profile setup is incomplete; see the messages above."
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
