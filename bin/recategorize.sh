#!/usr/bin/env bash
# Find YouTube videos in RSS category and move them to the video category.
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

echo "🔄 YouTube RSS Recategorizer"
echo "=============================="

cursor=""
total_scanned=0
total_found=0
total_updated=0

while true; do
  args=(reader-list-documents
    --category rss
    --response-fields source_url,location
    --limit 100
    --json)
  [ -n "$cursor" ] && args+=(--page-cursor "$cursor")

  local_result=$(fetch_page "${args[@]}")

  page_count=$(echo "$local_result" | jq '.results | length // 0')
  total_scanned=$((total_scanned + page_count))

  # YouTube videos in new/later/feed locations not yet in video category
  docs=$(echo "$local_result" | jq '[
    .results[] |
    select(
      (.location == "new" or .location == "later" or .location == "feed") and
      (.source_url // "" | ascii_downcase | test("youtube\\.com"))
    ) |
    {document_id: .id, category: "video"}
  ]')

  found=$(echo "$docs" | jq 'length // 0')
  total_found=$((total_found + found))

  if [ "$found" -gt 0 ]; then
    offset=0
    batch_updated=0
    while [ "$offset" -lt "$found" ]; do
      batch=$(echo "$docs" | jq ".[${offset}:$((offset + 50))]")
      batch_result=$(readwise reader-bulk-edit-document-metadata \
        --documents "$batch" --json 2>/dev/null) || batch_result='{"results":[]}'
      count=$(echo "$batch_result" | jq '[.results[] | select(.success)] | length // 0')
      batch_updated=$((batch_updated + count))
      offset=$((offset + 50))
      if [ "$offset" -lt "$found" ]; then sleep 3; fi
    done
    total_updated=$((total_updated + batch_updated))
    echo "   📄 Page: $page_count docs, $found YouTube → recategorized $batch_updated"
  else
    echo "   📄 Page: $page_count docs, 0 YouTube"
  fi

  cursor=$(echo "$local_result" | jq -r '.nextPageCursor // empty')
  if [ -z "$cursor" ]; then
    break
  fi
  sleep 3
done

echo ""
echo "📊 Summary:"
echo "   📄 Total RSS docs scanned: $total_scanned"
echo "   🎬 YouTube items found: $total_found"
echo "   ✅ Successfully recategorized: $total_updated"
