#!/usr/bin/env bash
set -euo pipefail

for ponytail_command in claude codex jq; do
    if ! command -v "$ponytail_command" >/dev/null 2>&1; then
        echo "Required command is unavailable: $ponytail_command" >&2
        exit 1
    fi
done

ponytail_claude_marketplaces="$(claude plugin marketplace list --json)"
if ! jq -e '.[] | select(.name == "ponytail")' <<< "$ponytail_claude_marketplaces" >/dev/null; then
    claude plugin marketplace add DietrichGebert/ponytail
elif ! jq -e '.[] | select(.name == "ponytail" and .source == "github" and .repo == "DietrichGebert/ponytail")' <<< "$ponytail_claude_marketplaces" >/dev/null; then
    echo "Claude marketplace ponytail points to another source" >&2
    exit 1
fi

if ! claude plugin list --json | jq -e '.[] | select(.id == "ponytail@ponytail" and .scope == "user")' >/dev/null; then
    claude plugin install ponytail@ponytail
fi

ponytail_codex_marketplaces="$(codex plugin marketplace list --json)"
if ! jq -e '.marketplaces[] | select(.name == "ponytail")' <<< "$ponytail_codex_marketplaces" >/dev/null; then
    codex plugin marketplace add DietrichGebert/ponytail
elif ! jq -e '.marketplaces[] | select(.name == "ponytail" and .marketplaceSource.sourceType == "git" and .marketplaceSource.source == "https://github.com/DietrichGebert/ponytail.git")' <<< "$ponytail_codex_marketplaces" >/dev/null; then
    echo "Codex marketplace ponytail points to another source" >&2
    exit 1
fi

if ! codex plugin list --json | jq -e '.installed[] | select(.pluginId == "ponytail@ponytail" and .installed == true)' >/dev/null; then
    codex plugin add ponytail@ponytail
fi
