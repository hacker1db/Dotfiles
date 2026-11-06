#!/usr/bin/env bash
#
# Claude Code status line — nicknisi/dotfiles (MIT), April 2026 layout on the
# current script's internals. One left-aligned line with dim │ separators:
#   branch │ model │ $ cost │ lines │ 󰧑 context bar (tokens) │ 󰉁 5h ╱ 7d │ style
# Usage comes from the rate_limits field Claude Code passes on stdin (never
# from the keychain), and icons are spelled as UTF-8 bytes because macOS
# ships bash 3.2, whose printf does not interpret \u / \U escapes.

ESC=$(printf '\033')
RED="${ESC}[0;31m"
GREEN="${ESC}[0;32m"
YELLOW="${ESC}[0;33m"
BLUE="${ESC}[0;34m"
MAGENTA="${ESC}[0;35m"
CYAN="${ESC}[0;36m"
WHITE="${ESC}[0;37m"
DIM="${ESC}[2m"
RESET="${ESC}[0m"

# Separator (minimal style)
SEP="${DIM}│${RESET}"

# Nerd font icons (colorized)
ICON_BRANCH="${GREEN}$(printf '\xee\x9c\xa5')${RESET}"          # nf-dev-git_branch U+E725
ICON_CONTEXT="${MAGENTA}$(printf '\xf3\xb0\xa7\x91')${RESET}"   # nf-md-brain       U+F09D1
ICON_COST="${GREEN}$(printf '\xef\x85\x95')${RESET}"            # nf-fa-dollar      U+F155
ICON_STYLE="${CYAN}$(printf '\xf3\xb0\x8f\x98')${RESET}"        # nf-md-palette     U+F03D8
ICON_USAGE="${YELLOW}$(printf '\xf3\xb0\x89\x81')${RESET}"      # nf-md-gauge       U+F0241
ICON_LINES="${CYAN}$(printf '\xef\x91\x80')${RESET}"            # nf-fa-file_text   U+F440

# Feature flags (set env vars to 0 to disable)
SHOW_CONTEXT_TOKENS="${CLAUDE_STATUSLINE_TOKENS:-1}"
SHOW_USAGE="${CLAUDE_STATUSLINE_USAGE:-1}"

# Read JSON input from stdin
input=$(cat)

# Tee rate_limits to a cache for sketchybar's usage pill (push, no polling
# on the bar side). Writes atomically and only fires the trigger when the
# payload actually changed, so most statusline refreshes cost one jq.
# Enterprise billing omits rate_limits entirely, so this is a no-op there.
tee_usage_cache() {
  local cache="$HOME/.cache/claude-usage.json" limits
  limits=$(echo "$input" | jq -c '.rate_limits // empty' 2>/dev/null)
  [ -n "$limits" ] || return 0
  [ "$limits" = "$(cat "$cache" 2>/dev/null)" ] && return 0
  printf '%s' "$limits" >"${cache}.tmp" && mv "${cache}.tmp" "$cache"
  command -v sketchybar >/dev/null 2>&1 && sketchybar --trigger claude_usage_update &
}
tee_usage_cache

# Helper functions for extracting data
get_model_name() { echo "$input" | jq -r '.model.display_name // "Unknown Model"' | sed 's/ (.*)//'; }

# Get model-specific icon based on model name
get_model_icon() {
  local model_name=$(get_model_name)
  case "$model_name" in
  *[Ff]able* | *[Mm]ythos*) printf "${MAGENTA}\xf3\xb0\x97\x9a${RESET}" ;; # nf-md-book_open_page_variant U+F05DA
  *[Oo]pus*) printf "${MAGENTA}\xf3\xb0\x87\xa5${RESET}" ;;   # nf-md-brain_freeze U+F01E5
  *[Ss]onnet*) printf "${CYAN}\xf3\xb0\x9d\x9a${RESET}" ;;    # nf-md-music_note   U+F075A
  *[Hh]aiku*) printf "${GREEN}\xf3\xb0\x9c\xb5${RESET}" ;;    # nf-md-leaf         U+F0735
  *) printf "${DIM}\xf3\xb0\x9a\xa9${RESET}" ;;               # nf-md-robot        U+F06A9
  esac
}
get_output_style() { echo "$input" | jq -r '.output_style.name // "default"'; }
get_cost() {
  local cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
  printf "${DIM}\$%.2f${RESET}" "$cost"
}

get_lines_changed() {
  local added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
  local removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
  [ "$added" = "0" ] && [ "$removed" = "0" ] && return
  printf "${GREEN}+%d${RESET}/${RED}-%d${RESET}" "$added" "$removed"
}

get_agent_name() {
  echo "$input" | jq -r '.agent.name // empty'
}

get_context_percent() {
  local percent=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
  printf "%.0f" "$percent"
}

get_context_used() {
  local percent=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
  local window=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
  local used=$(echo "$percent * $window / 100" | bc)
  if [ "$used" -ge 1000 ]; then
    printf "%.0fK" "$(echo "scale=0; $used / 1000" | bc)"
  else
    printf "%d" "$used"
  fi
}

# Build a progress bar with color based on percentage
build_context_bar() {
  local used=$(get_context_percent)
  local remaining=$((100 - used))
  local bar_width=5
  local filled=$((remaining * bar_width / 100))
  local empty=$((bar_width - filled))

  [ "$filled" -gt "$bar_width" ] && filled=$bar_width && empty=0
  [ "$filled" -lt 0 ] && filled=0 && empty=$bar_width

  local bar_color
  if [ "$remaining" -gt 50 ]; then
    bar_color="$GREEN"
  elif [ "$remaining" -gt 20 ]; then
    bar_color="$YELLOW"
  else
    bar_color="$RED"
  fi

  local bar=""
  for ((i = 0; i < filled; i++)); do bar+="━"; done
  for ((i = 0; i < empty; i++)); do bar+="╌"; done

  if [ "$SHOW_CONTEXT_TOKENS" = "1" ]; then
    local tokens=$(get_context_used)
    printf "%s%s%s %d%% ${DIM}(%s)${RESET}" "$bar_color" "$bar" "$RESET" "$remaining" "$tokens"
  else
    printf "%s%s%s %d%%" "$bar_color" "$bar" "$RESET" "$remaining"
  fi
}

# ── Usage limits ──────────────────────────────────────────────────────────────
#
# Source: the `rate_limits` field Claude Code passes in on stdin. This is
# normalized per-session, so it reflects the CURRENT account (Max subscription
# vs. enterprise) — no keychain/token guessing. Enterprise billing omits the
# field entirely, so nothing renders. `resets_at` is epoch seconds.

format_time_until() {
  local reset_epoch="$1"
  [ -z "$reset_epoch" ] && { echo "?"; return; }

  local now
  now=$(date "+%s")
  if [ "$now" -ge "$reset_epoch" ]; then
    echo "now"
    return
  fi

  local secs=$((reset_epoch - now))
  local mins=$((secs / 60))
  local hours=$((mins / 60))
  local days=$((hours / 24))

  if [ "$days" -gt 0 ]; then
    printf "%dd%dh" "$days" $((hours % 24))
  elif [ "$hours" -gt 0 ]; then
    printf "%dh%dm" "$hours" $((mins % 60))
  else
    printf "%dm" "$mins"
  fi
}

# Build a mini usage bar for a single window
# Args: $1=remaining_pct (0-100), $2=label ("5h"/"7d"), $3=time_until
build_usage_bar() {
  local remaining="$1" label="$2" time_until="$3"
  local bar_width=5
  local filled=$((remaining * bar_width / 100))
  local empty=$((bar_width - filled))

  [ "$filled" -gt "$bar_width" ] && filled=$bar_width && empty=0
  [ "$filled" -lt 0 ] && filled=0 && empty=$bar_width

  local bar_color
  if [ "$remaining" -gt 50 ]; then
    bar_color="$GREEN"
  elif [ "$remaining" -gt 20 ]; then
    bar_color="$YELLOW"
  else
    bar_color="$RED"
  fi

  local bar=""
  for ((i = 0; i < filled; i++)); do bar+="━"; done
  for ((i = 0; i < empty; i++)); do bar+="╌"; done

  printf "${DIM}%s${RESET} %s%s%s %d%% ${DIM}↻%s${RESET}" \
    "$label" "$bar_color" "$bar" "$RESET" "$remaining" "$time_until"
}

# Render one rate-limit window from stdin, or nothing if it's absent.
# Args: $1=json key (five_hour/seven_day), $2=label (5h/7d)
render_usage_window() {
  local key="$1" label="$2"
  local used reset
  used=$(echo "$input" | jq -r ".rate_limits.${key}.used_percentage // empty")
  reset=$(echo "$input" | jq -r ".rate_limits.${key}.resets_at // empty")
  [ -z "$reset" ] && return
  used=$(printf "%.0f" "${used:-0}")
  build_usage_bar "$((100 - used))" "$label" "$(format_time_until "$reset")"
}

# Build usage display string from stdin rate_limits
build_usage_display() {
  [ "$SHOW_USAGE" = "1" ] || return

  local five seven
  five=$(render_usage_window five_hour "5h")
  seven=$(render_usage_window seven_day "7d")

  if [ -n "$five" ] && [ -n "$seven" ]; then
    printf "%s ${DIM}╱${RESET} %s" "$five" "$seven"
  else
    printf "%s%s" "$five" "$seven"
  fi
}

# ── Extract values ────────────────────────────────────────────────────────────
model=$(get_model_name)
model_icon=$(get_model_icon)
output_style=$(get_output_style)
cost_display=$(get_cost)
context_bar=$(build_context_bar)
usage_display=$(build_usage_display)
lines_display=$(get_lines_changed)
agent_name=$(get_agent_name)
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git")

# Terminal width for adaptive display. Claude Code exports COLUMNS (2.1.153+);
# tmux's #{pane_width} answers for the client's active pane, so it is only a
# fallback.
term_width="${COLUMNS:-0}"
case "$term_width" in *[!0-9]* | '') term_width=0 ;; esac
if [ "$term_width" -lt 40 ] && [ -n "$TMUX" ]; then
  term_width=$(tmux display-message -p '#{pane_width}' 2>/dev/null || echo 0)
fi
if [ "$term_width" -lt 40 ]; then
  term_width=$(tput cols 2>/dev/null || echo 200)
fi

# ── Build segments — order: identity → impact → resources → meta ─────────────
seg_add() {
  if [ -n "$statusline" ]; then
    statusline+=" ${SEP} "
  fi
  statusline+="$1"
}

statusline=""

# Identity (only show model if not Opus)
if [[ "$model" != *[Oo]pus* ]]; then
  statusline+="${model_icon} ${MAGENTA}${model}${RESET}"
fi
if [ -n "$agent_name" ]; then
  statusline+=" ${DIM}(${agent_name})${RESET}"
fi

# Session impact
seg_add "${ICON_COST} ${cost_display}"
if [ -n "$lines_display" ]; then
  seg_add "${ICON_LINES} ${lines_display}"
fi

# Resource gauges
seg_add "${ICON_CONTEXT} ${context_bar}"
if [ -n "$usage_display" ]; then
  seg_add "${ICON_USAGE} ${usage_display}"
fi

# Meta (collapsible)
if [ "$term_width" -gt 160 ] && [ "$output_style" != "default" ]; then
  seg_add "${ICON_STYLE} ${DIM}${output_style}${RESET}"
fi

# Prepend branch on wide terminals
if [ "$term_width" -gt 120 ]; then
  statusline="${ICON_BRANCH} ${GREEN}${git_branch}${RESET} ${SEP} ${statusline}"
fi

printf '%s\n' "$statusline"
