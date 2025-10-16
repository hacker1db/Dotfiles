#!/usr/bin/env bash
# Logging helpers (colorized)
COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() { echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}\n${COLOR_GRAY}==============================${COLOR_NONE}"; }
info() { echo -e "${COLOR_BLUE}Info:${COLOR_NONE} $1"; }
warning() { echo -e "${COLOR_YELLOW}Warning:${COLOR_NONE} $1"; }
error() { echo -e "${COLOR_RED}Error:${COLOR_NONE} $1"; }
success() { echo -e "${COLOR_GREEN}$1${COLOR_NONE}"; }
