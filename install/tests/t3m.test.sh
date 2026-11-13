#!/usr/bin/env bash
# Tests bin/t3m against a stub `t3` and a fixture state database.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/t3m-test.XXXXXX")"
trap 'rm -rf "$FIXTURE"' EXIT

export T3CODE_HOME="$FIXTURE/t3home"
mkdir -p "$T3CODE_HOME/userdata" "$FIXTURE/bin" "$FIXTURE/work/repo/sub" "$FIXTURE/work/repo-other"
WORK="$(cd "$FIXTURE/work" && pwd -P)"

sqlite3 "$T3CODE_HOME/userdata/statev2.sqlite" <<SQL
CREATE TABLE projection_projects (project_id TEXT PRIMARY KEY, title TEXT, workspace_root TEXT,
  updated_at TEXT, deleted_at TEXT, pinned_at TEXT, archived_at TEXT);
CREATE TABLE orchestration_v2_projection_threads (thread_id TEXT PRIMARY KEY, project_id TEXT,
  title TEXT, updated_at TEXT, archived_at TEXT, deleted_at TEXT, payload_json TEXT);
INSERT INTO projection_projects VALUES
  ('p1', 'Repo', '$WORK/repo', '2026-01-02', NULL, NULL, NULL),
  ('p2', 'Other', '$WORK/repo-other', '2026-01-01', NULL, NULL, NULL),
  ('p3', 'Gone', '$WORK/gone', '2026-01-03', '2026-01-04', NULL, NULL);
INSERT INTO orchestration_v2_projection_threads VALUES
  ('t1', 'p1', 'First', '2026-01-01T10:00:00Z', NULL, NULL, '{}'),
  ('t2', 'p1', 'Child', '2026-01-02T10:00:00Z', NULL, NULL, '{"lineage":{"parentThreadId":"t1"}}'),
  ('t3', 'p2', 'Other thread', '2026-01-03T10:00:00Z', NULL, NULL, '{}');
SQL
printf '{"manifest":{"currentModels":{"claudeAgent":["claude-opus-5-5"],"codex":["gpt-6-astra"]}}}' \
  > "$T3CODE_HOME/userdata/model-manifest.json"

# Stub t3: record argv and stdin.
cat > "$FIXTURE/bin/t3" <<'BIN'
#!/bin/sh
printf '%s\n' "$*" > "$T3CODE_HOME/argv"
for last; do :; done
if [ "$last" = - ]; then cat > "$T3CODE_HOME/stdin"; fi
BIN
chmod +x "$FIXTURE/bin/t3"
export PATH="$FIXTURE/bin:$PATH"
T3M="$ROOT/bin/t3m"

fail() { echo "FAIL: $*" >&2; exit 1; }
eq() { [ "$1" = "$2" ] || fail "$3: expected [$2], got [$1]"; }

eq "$("$T3M" _projects | cut -f1 | tr '\n' ' ')" "p1 p2 " "deleted projects hidden"
eq "$("$T3M" _threads | cut -f1 | tr '\n' ' ')" "t3 t1 " "subagent threads hidden, newest first"
eq "$("$T3M" _threads Repo | cut -f1)" "t1" "threads filtered by project title"
eq "$("$T3M" _threads "$WORK/repo/sub" | cut -f1)" "t1" "threads filtered by nested path"
eq "$("$T3M" _models | wc -l | tr -d ' ')" "2" "models listed"

"$T3M" new Repo --model claude-opus-5-5 --worktree main --branch feat/x fix the tests </dev/null
eq "$(cat "$T3CODE_HOME/argv")" "thread start --model claude-opus-5-5 --worktree main --branch feat/x p1 -" "new argv"
eq "$(cat "$T3CODE_HOME/stdin")" "fix the tests" "new message via stdin"

(cd "$WORK/repo-other" && "$T3M" new . "it's quoted; \$HOME" </dev/null)
eq "$(cat "$T3CODE_HOME/argv")" "thread start p2 -" "new resolves ."
eq "$(cat "$T3CODE_HOME/stdin")" "it's quoted; \$HOME" "message passed verbatim"

"$T3M" send t1 --wait keep going </dev/null
eq "$(cat "$T3CODE_HOME/argv")" "thread send --wait t1 -" "send argv"

"$T3M" service restart </dev/null
eq "$(cat "$T3CODE_HOME/argv")" "service restart" "unknown commands pass through"

if "$T3M" new nope hi </dev/null 2>/dev/null; then fail "unknown project should fail"; fi

# zsh completion file must at least parse and define _t3m.
zsh -fc "fpath=($ROOT/zsh/functions \$fpath); autoload -U compinit; compinit -u -D; autoload -U _t3m; (( \$+functions[_t3m] ))" \
  || fail "_t3m does not load"

echo 't3m tests passed'
