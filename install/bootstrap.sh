#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/hacker1db/Dotfiles.git}"
ROOT="$HOME/.dotfiles"
BRANCH="${DOTFILES_BRANCH:-main}"

if [[ -L "$ROOT" || ( -e "$ROOT" && ! -d "$ROOT/.bare" ) ]]; then
    echo "$ROOT exists but is not a bare-clone layout; move it aside and rerun." >&2
    exit 1
fi

if [[ ! -d "$ROOT/.bare" ]]; then
    mkdir -p "$ROOT"
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
