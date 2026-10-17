#!/usr/bin/env bash

set -euo pipefail

brew_prefix=""
if command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix 2>/dev/null || true)"
fi

DOTNET_ROOT=""
for candidate in \
    "$brew_prefix/opt/dotnet/libexec" \
    /opt/homebrew/opt/dotnet/libexec \
    /usr/local/opt/dotnet/libexec \
    /home/linuxbrew/.linuxbrew/opt/dotnet/libexec \
    "$HOME/.dotnet"; do
    if [ -x "$candidate/dotnet" ]; then
        DOTNET_ROOT="$candidate"
        break
    fi
done

if [ -n "$DOTNET_ROOT" ]; then
    export DOTNET_ROOT
    export PATH="$DOTNET_ROOT:$PATH"
fi
export PATH="$HOME/.dotnet/tools:$PATH"

if ! command -v dotnet >/dev/null 2>&1; then
    echo "dotnet not found, skipping .NET global tools"
    # install.sh sources this script; return so later phases still run.
    return 0 2>/dev/null || exit 0
fi

tools=(
    "csharp-ls"
)

for tool in "${tools[@]}"; do
    echo "Installing $tool..."
    dotnet tool update --global "$tool" || dotnet tool install --global "$tool"
done

echo ".NET global tools setup complete"
