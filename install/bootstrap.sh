#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/hacker1db/Dotfiles.git}"
ROOT="$HOME/.dotfiles"
BRANCH="${DOTFILES_BRANCH:-main}"

missing=()
for tool in git gh pnpm pandoc; do
    command -v "$tool" > /dev/null 2>&1 || missing+=("$tool")
done
if ! command -v node > /dev/null 2>&1 || (( $(node -p 'process.versions.node.split(".")[0]') < 20 )); then
    missing+=("node (20+)")
fi
if (( ${#missing[@]} )); then
    echo "Missing requirements: ${missing[*]}" >&2
    echo "Install them (macOS: brew install git gh node pnpm pandoc) and rerun." >&2
    exit 1
fi

if [[ -z "${PLAN_MANAGER_REPO_URL:-}" ]] && ! gh auth status > /dev/null 2>&1; then
    if [[ "${DOTFILES_NONINTERACTIVE:-0}" == 1 ]]; then
        echo "GitHub CLI is not logged in; run gh auth login and rerun." >&2
        exit 1
    fi
    echo "Log in to GitHub to continue."
    gh auth login
fi

if [[ -L "$ROOT" || ( -e "$ROOT" && ! -d "$ROOT/.bare" ) ]]; then
    echo "$ROOT exists but is not a bare-clone layout; move it aside and rerun." >&2
    exit 1
fi

if [[ ! -d "$ROOT/.bare" ]]; then
    git clone --bare "$REPO_URL" "$ROOT/.bare"
    echo "gitdir: ./.bare" > "$ROOT/.git"
    git --git-dir="$ROOT/.bare" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
fi

git --git-dir="$ROOT/.bare" fetch origin

if [[ ! -d "$ROOT/$BRANCH" ]]; then
    git --git-dir="$ROOT/.bare" worktree add "$ROOT/$BRANCH" "$BRANCH"
    git -C "$ROOT/$BRANCH" branch --set-upstream-to="origin/$BRANCH"
fi

exec "$ROOT/$BRANCH/install.sh" "${@:-all}"
