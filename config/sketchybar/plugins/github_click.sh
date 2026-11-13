#!/usr/bin/env bash
# GitHub chip clicks: left = toggle the PR dropdown, right = the old
# behavior (open the pulls page).

case "$BUTTON" in
right)
  open https://github.com/pulls/review-requested
  ;;
*)
  sketchybar --set github popup.drawing=toggle
  ;;
esac
