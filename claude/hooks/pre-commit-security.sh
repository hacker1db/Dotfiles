#!/usr/bin/env bash
# Pre-commit security scan — runs before every `git commit` via Claude Code PreToolUse hook.
# Uses GitGuardian (ggshield) for secret detection and SonarQube CLI for open issue listing.
# ggshield failures are BLOCKING (exit 1); sonar issues are informational (exit 0 with warnings).
#
# Install:
#   ggshield:   pip install ggshield && ggshield auth login
#   sonar CLI:  curl -o- https://raw.githubusercontent.com/SonarSource/sonarqube-cli/refs/heads/master/user-scripts/install.sh | bash
#
# Required env vars for sonar (add to ~/.zshrc or ~/.zshenv):
#   export SONARQUBE_CLI_TOKEN=<your-user-token>
#   export SONARQUBE_CLI_SERVER=<https://your-sonarqube-server>

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

# ── SonarQube issue list ───────────────────────────────────────────────────────
if command -v sonar &>/dev/null; then
  # Resolve project key: sonar-project.properties → pipeline YAML → skip
  SONAR_KEY=""

  if [[ -f "sonar-project.properties" ]]; then
    SONAR_KEY=$(grep -E "^sonar\.projectKey\s*=" sonar-project.properties 2>/dev/null \
      | sed 's/.*=\s*//' | tr -d '[:space:]')
  fi

  if [[ -z "$SONAR_KEY" ]] && [[ -f "ci/azure-pipelines-sdp.yml" ]]; then
    PREFIX=$(grep -A1 "SonarQubeProjectNamePrefix" ci/azure-pipelines-sdp.yml 2>/dev/null \
      | grep "value:" | sed 's/.*value:\s*//' | tr -d "' \n")
    PROJ=$(grep -A1 "^  - name: ProjectName" ci/azure-pipelines-sdp.yml 2>/dev/null \
      | grep "value:" | sed 's/.*value:\s*//' | tr -d "' \n")
    [[ -n "$PREFIX" && -n "$PROJ" ]] && SONAR_KEY="${PREFIX}-${PROJ}"
  fi

  if [[ -n "$SONAR_KEY" ]]; then
    echo ""
    echo "[sonar] Fetching open issues for project: $SONAR_KEY ..."
    SONAR_OUT=$(sonar list issues -p "$SONAR_KEY" 2>&1)
    SONAR_EXIT=$?
    if [[ $SONAR_EXIT -ne 0 ]]; then
      echo "[sonar] Warning: could not fetch issues (auth or connectivity issue)."
      echo "$SONAR_OUT" | tail -5
    else
      ISSUE_COUNT=$(echo "$SONAR_OUT" | grep -cE "^\s*\|" 2>/dev/null || echo "?")
      echo "[sonar] $ISSUE_COUNT open issue(s) — check SonarQube dashboard for details."
      echo "$SONAR_OUT" | grep -iE "BLOCKER|CRITICAL" | head -10
    fi
  else
    echo ""
    echo "[sonar] Could not resolve project key — skipping issue check."
    echo "        Add sonar.projectKey to sonar-project.properties or ci/azure-pipelines-sdp.yml"
  fi
else
  echo ""
  echo "[sonar] Not installed — skipping SonarQube issue check."
  echo "        Install: curl -o- https://raw.githubusercontent.com/SonarSource/sonarqube-cli/refs/heads/master/user-scripts/install.sh | bash"
fi

exit $HARD_FAIL
