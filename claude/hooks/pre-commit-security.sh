#!/usr/bin/env bash
STAGED=$(git diff --cached --name-only 2>/dev/null)
[[ -z "$STAGED" ]] && exit 0

HARD_FAIL=0

# ── GitGuardian secret scan ────────────────────────────────────────────────────
if command -v ggshield &>/dev/null; then
  echo "[ggshield] Running secret scan on staged changes..."
  if ! ggshield secret scan pre-commit 2>&1; then
    echo ""
    echo "[ggshield] BLOCKED: Secrets detected in staged changes — commit aborted."
    echo "           Fix the findings above, then re-stage and retry."
    HARD_FAIL=1
  else
    echo "[ggshield] Clean — no secrets detected."
  fi
else
  echo "[ggshield] Not installed — skipping secret scan."
  echo "           Install: pip install ggshield && ggshield auth login"
fi

exit $HARD_FAIL
