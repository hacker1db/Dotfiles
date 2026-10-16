#!/usr/bin/env bash
# Find YouTube Shorts in video and rss categories, tag with youtube-shorts, and archive.
set -uo pipefail

fetch_page() {
  local attempts=0
  local result
  while [ $attempts -lt 3 ]; do
    result=$(readwise "$@" 2>/dev/null) || result=""
    if echo "$result" | jq -e '.results' > /dev/null 2>&1; then
      echo "$result"
      return 0
    fi
    attempts=$((attempts + 1))
    echo "   ⚠️  API error (attempt $attempts/3), retrying in 15s..." >&2
    sleep 15
  done
  echo '{"results":[],"nextPageCursor":null}'
}

process_category() {
  local category="$1"
  local cursor=""
  local total_scanned=0
  local total_found=0
  local total_archived=0

  echo "📂 Scanning $category category..."

  while true; do
    local args=(reader-list-documents
      --category "$category"
      --response-fields source_url,tags,location
      --limit 100
      --json)
    [ -n "$cursor" ] && args+=(--page-cursor "$cursor")

    local result
    result=$(fetch_page "${args[@]}")

    local page_count
    page_count=$(echo "$result" | jq '.results | length // 0')
    total_scanned=$((total_scanned + page_count))

    # Non-archived Shorts; merge existing tags with youtube-shorts
    local docs
    docs=$(echo "$result" | jq '[
      .results[] |
      select(
        (.location != "archive") and
        (.source_url // "" | ascii_downcase | test("youtube\\.com/shorts"))
      ) |
      {
        document_id: .id,
        tags: ([(.tags // {} | keys[]), "youtube-shorts"] | unique),
        location: "archive"
      }
    ]')

    local found
    found=$(echo "$docs" | jq 'length // 0')
    total_found=$((total_found + found))

    if [ "$found" -gt 0 ]; then
      local offset=0
      local batch_archived=0
      while [ "$offset" -lt "$found" ]; do
        local batch batch_result count
        batch=$(echo "$docs" | jq ".[${offset}:$((offset + 50))]")
        batch_result=$(readwise reader-bulk-edit-document-metadata \
          --documents "$batch" --json 2>/dev/null) || batch_result='{"results":[]}'
        count=$(echo "$batch_result" | jq '[.results[] | select(.success)] | length // 0')
        batch_archived=$((batch_archived + count))
        offset=$((offset + 50))
        if [ "$offset" -lt "$found" ]; then sleep 3; fi
      done
      total_archived=$((total_archived + batch_archived))
      echo "   📄 Page: $page_count docs, $found shorts → archived $batch_archived"
    else
      echo "   📄 Page: $page_count docs, 0 shorts"
    fi

    cursor=$(echo "$result" | jq -r '.nextPageCursor // empty')
    if [ -z "$cursor" ]; then
      break
    fi
    sleep 3
  done

  echo "   📊 $category: scanned $total_scanned, found $total_found, archived $total_archived"
}

echo "🎬 YouTube Shorts Remover"
echo "=========================="

process_category "video"
echo ""
process_category "rss"

echo ""
echo "✅ Done!"
