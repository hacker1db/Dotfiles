#!/usr/bin/env bash
# Claude Code status line — model, context bar, tokens remaining

input=$(cat)

# Directory (just the current folder name)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
short_dir=$(basename "$cwd")

# Git branch
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
model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""' | sed 's/ *([^)]*context[^)]*)//i')

# Context usage bar and tokens remaining
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

ctx_part=""
if [ "$ctx_size" -gt 0 ] 2>/dev/null; then
  # Calculate used/remaining tokens from current_usage (accurate context state)
  used_tokens=$(echo "$input" | jq -r '
    (.context_window.current_usage.input_tokens // 0)
    + (.context_window.current_usage.cache_creation_input_tokens // 0)
    + (.context_window.current_usage.cache_read_input_tokens // 0)')
  remaining_tokens=$((ctx_size - used_tokens))

  # Format token count (e.g. 920K, 1.0M)
  if [ "$remaining_tokens" -ge 1000000 ]; then
    tokens_fmt=$(awk "BEGIN { printf \"%.1fM\", $remaining_tokens/1000000 }")
  elif [ "$remaining_tokens" -ge 1000 ]; then
    tokens_fmt=$(awk "BEGIN { printf \"%.0fK\", $remaining_tokens/1000 }")
  else
    tokens_fmt="${remaining_tokens}"
  fi

  # Build loading bar (20 chars wide)
  bar_width=20
  used_int=${used_pct%.*}
  [ -z "$used_int" ] && used_int=0
  filled=$(( (used_int * bar_width + 50) / 100 ))
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width

  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar="${bar}#"
    i=$((i + 1))
  done
  while [ "$i" -lt "$bar_width" ]; do
    bar="${bar}-"
    i=$((i + 1))
  done

  # Color: green <50%, yellow 50-80%, red >80%
  if [ "$used_int" -le 50 ]; then
    bar_color="\033[32m"  # green
  elif [ "$used_int" -le 80 ]; then
    bar_color="\033[33m"  # yellow
  else
    bar_color="\033[31m"  # red
  fi

  used_pct_fmt=$(awk "BEGIN { printf \"%.1f\", $used_pct }")

  ctx_part=$(printf " | %b[%s]\033[0m %s%% of context used | ~%s tokens left" \
    "$bar_color" "$bar" "$used_pct_fmt" "$tokens_fmt")
fi

printf "\033[36m%s\033[0m\033[90m%s\033[0m\033[33m%s\033[0m%s" \
  "$short_dir" \
  "$git_status" \
  "${model:+ [$model]}" \
  "$ctx_part"
