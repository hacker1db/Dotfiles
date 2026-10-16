#!/usr/bin/env bash
# Claude Code PreToolUse hook (matcher: Bash). Scans staged changes for secrets
# before `git commit`. Exit 2 blocks the tool call; stderr is shown to Claude.

# Only act on git commit commands; the matcher fires for every Bash call.
if [[ ! -t 0 ]]; then
  INPUT=$(cat)
  if command -v jq &>/dev/null; then
    COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT" 2>/dev/null)
  else
    COMMAND=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' <<<"$INPUT" 2>/dev/null)
  fi
  [[ "$COMMAND" =~ (^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$) ]] || exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null)
[[ -z "$STAGED" ]] && exit 0

HARD_FAIL=0

# ── GitGuardian secret scan ────────────────────────────────────────────────────
if command -v ggshield &>/dev/null; then
  echo "[ggshield] Running secret scan on staged changes..." >&2
  if ! ggshield secret scan pre-commit >&2; then
    echo "" >&2
    echo "[ggshield] BLOCKED: Secrets detected in staged changes — commit aborted." >&2
    echo "           Fix the findings above, then re-stage and retry." >&2
    HARD_FAIL=2
  else
    echo "[ggshield] Clean — no secrets detected." >&2
  fi
else
  echo "[ggshield] Not installed — skipping secret scan." >&2
  echo "           Install: pip install ggshield && ggshield auth login" >&2
fi

exit $HARD_FAIL
