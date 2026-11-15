#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

SLOTS=10
PLAN_BIN=$(command -v plan || echo "$HOME/.local/bin/plan")

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

PLANS=$("$PLAN_BIN" list --status active --json 2>/dev/null)
COUNT=$(jq '.plans | length' <<<"$PLANS" 2>/dev/null)

if [ -z "$COUNT" ] || [ "$COUNT" -eq 0 ]; then
  sketchybar --set "$NAME" drawing=off popup.drawing=off
  exit 0
fi

ARGS=(--animate tanh 15 --set "$NAME" drawing=on
  label="$COUNT plans" label.color="$FG" icon.color="$FG")

i=0
while IFS=$'\t' read -r ID TITLE; do
  if [ "$i" -eq $((SLOTS - 1)) ] && [ "$COUNT" -gt "$SLOTS" ]; then
    ARGS+=(--set "$NAME.popup.$i" drawing=on icon=→
      label="+$((COUNT - i)) more  ·  open dashboard"
      click_script="'$PLAN_BIN' open; sketchybar --set plans popup.drawing=off")
    i=$((i + 1))
    break
  fi
  ARGS+=(--set "$NAME.popup.$i" drawing=on label="$TITLE"
    click_script="'$PLAN_BIN' open '$ID'; sketchybar --set plans popup.drawing=off")
  i=$((i + 1))
done < <(jq -r '.plans | sort_by(.updated) | reverse | .[] | [.id, .title] | @tsv' <<<"$PLANS")

for ((j = i; j < SLOTS; j++)); do
  ARGS+=(--set "$NAME.popup.$j" drawing=off)
done

sketchybar "${ARGS[@]}"
