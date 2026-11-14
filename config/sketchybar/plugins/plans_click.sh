#!/usr/bin/env bash

case "$BUTTON" in
right)
  "$(command -v plan || echo "$HOME/.local/bin/plan")" open
  ;;
*)
  sketchybar --set plans popup.drawing=toggle
  ;;
esac
