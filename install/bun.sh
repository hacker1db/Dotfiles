#!/usr/bin/env bash

echo "Setting up bun global packages"

if ! command -v bun &>/dev/null; then
  echo "bun not found, skipping"
  exit 0
fi

packages=(
  "@azure/static-web-apps-cli"
  "@fission-ai/openspec"
  "@github/copilot"
  "eslint"
  "markdownlint-cli2"
  "md-to-pdf"
  "prettier"
  "typescript"
  "typescript-language-server"
  "vercel"
)

for pkg in "${packages[@]}"; do
  echo "Installing $pkg..."
  bun add -g "$pkg"
done

echo "Bun global packages setup complete"
