#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FIXTURE="$(mktemp -d /tmp/plan-zsh-test.XXXXXX)"
trap 'rm -rf "$FIXTURE"' EXIT
home="$FIXTURE/home with spaces"
mkdir -p "$home/.dotfiles/main/zsh/functions" "$home/.local/bin" "$home/Library/pnpm" "$FIXTURE/tools"
printf ':\n' > "$home/.dotfiles/main/zsh/empty.zsh"
printf ':\n' > "$home/.dotfiles/main/zsh/functions/zfetch"
sed "s|/opt/homebrew/bin|$FIXTURE/tools|g" "$ROOT/zsh/zshrc.symlink" > "$home/.zshrc"
cat > "$home/.local/bin/plan" <<'BIN'
#!/bin/sh
if [ "$*" = 'completion zsh' ]; then
    printf 'managed\n' >> "$HOME/completion-source"
    echo 'typeset -g PLAN_COMPLETION_SOURCE=managed'
fi
BIN
cat > "$home/Library/pnpm/plan" <<'BIN'
#!/bin/sh
printf 'legacy\n' >> "$HOME/completion-source"
exit 99
BIN
chmod +x "$home/.local/bin/plan" "$home/Library/pnpm/plan"
for pnpm in present absent; do
    if [ "$pnpm" = present ]; then
        printf '#!/bin/sh\nexit 0\n' > "$FIXTURE/tools/pnpm"
        chmod +x "$FIXTURE/tools/pnpm"
    else
        rm -f "$FIXTURE/tools/pnpm"
    fi
    HOME="$home" CACHEDIR="$home/cache" PATH="$home/Library/pnpm:$home/Library/pnpm:$FIXTURE/tools:/usr/bin:/bin" \
        /bin/zsh -ic '
            [[ $(whence -p plan) == "$HOME/.local/bin/plan" ]] || exit 10
            [[ $PLAN_COMPLETION_SOURCE == managed ]] || exit 11
            [[ ${(M)#path:#$HOME/Library/pnpm} == 1 ]] || exit 12
        ' > "$FIXTURE/stdout" 2> "$FIXTURE/stderr" || {
            cat "$FIXTURE/stdout" "$FIXTURE/stderr"
            echo "FAIL: fresh Zsh with pnpm $pnpm" >&2
            exit 1
        }
done
[[ $(cat "$home/completion-source") == $'managed\nmanaged' ]] || { echo 'FAIL: completions did not use managed CLI'; exit 1; }
echo 'plan-manager Zsh tests passed'
