#!/usr/bin/env bash

echo "Setting up Node global tools"

if ! command -v pnpm &>/dev/null; then
  echo "pnpm not found, skipping Node global tools"
  exit 0
fi

export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
mkdir -p "$PNPM_HOME"
export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"

tools=(
  "@azure/static-web-apps-cli"
  "@fission-ai/openspec"
  "@github/copilot"
  "@readwise/cli"
  "bmad-method"
  "eslint"
  "markdownlint-cli2"
  "md-to-pdf"
  "prettier"
  "typescript"
  "typescript-language-server"
  "vercel"
)

for tool in "${tools[@]}"; do
  echo "Installing $tool..."
  pnpm add --global "$tool"
done

# Authenticate Readwise CLI
# For headless/scripts: readwise login-with-token YOUR_ACCESS_TOKEN (get token at readwise.io/access_token)
if command -v readwise &>/dev/null; then
  echo "Logging into Readwise..."
  readwise login
fi

echo "Node global tools setup complete"
