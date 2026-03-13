#!/usr/bin/env bash
# Claude Code status line — mirrors Starship prompt style

input=$(cat)

# Directory (truncate to last 4 segments, like Starship truncation_length=4)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
short_dir=$(echo "$cwd" | awk -F'/' '{
  n=NF; if(n<=4) { print $0 } else {
    printf "...";
    for(i=n-3;i<=n;i++) printf "/%s",$i;
    print ""
  }
}')

# Git branch (skip optional locks to avoid blocking)
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks 2>/dev/null | grep -q true; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Git status summary
git_status=""
if [ -n "$branch" ]; then
  status_flags=$(git -C "$cwd" status --porcelain --no-optional-locks 2>/dev/null)
  modified=$(echo "$status_flags" | grep -c '^ M\|^M ' 2>/dev/null || true)
  untracked=$(echo "$status_flags" | grep -c '^??' 2>/dev/null || true)
  staged=$(echo "$status_flags" | grep -c '^[MADRCU]' 2>/dev/null || true)

  flags=""
  [ "$staged" -gt 0 ]    && flags="${flags}+"
  [ "$modified" -gt 0 ]  && flags="${flags}!"
  [ "$untracked" -gt 0 ] && flags="${flags}?"

  git_status=" ${branch}${flags:+ [${flags}]}"
fi

# Model
model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""')

# Context remaining
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
ctx_part=""
if [ -n "$remaining" ]; then
  remaining_int=${remaining%.*}
  if [ "$remaining_int" -le 10 ] 2>/dev/null; then
    ctx_part=" | ctx: ${remaining_int}% left (!)"
  else
    ctx_part=" | ctx: ${remaining_int}% left"
  fi
fi

printf "\033[36m%s\033[0m\033[90m%s\033[0m\033[33m%s\033[0m%s" \
  "$short_dir" \
  "$git_status" \
  "${model:+ | $model}" \
  "$ctx_part"
