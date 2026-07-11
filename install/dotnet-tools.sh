#!/usr/bin/env bash

set -euo pipefail

if [ -d /opt/homebrew/opt/dotnet/libexec ]; then
    export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
elif [ -d /usr/local/opt/dotnet/libexec ]; then
    export DOTNET_ROOT="/usr/local/opt/dotnet/libexec"
elif [ -d "$HOME/.dotnet" ]; then
    export DOTNET_ROOT="$HOME/.dotnet"
fi

if ! command -v dotnet >/dev/null 2>&1; then
    echo "dotnet not found, skipping .NET global tools"
    exit 0
fi

export PATH="${DOTNET_ROOT:-}:$HOME/.dotnet/tools:$PATH"

tools=(
    "csharp-ls"
)

for tool in "${tools[@]}"; do
    echo "Installing $tool..."
    dotnet tool update --global "$tool" || dotnet tool install --global "$tool"
done

echo ".NET global tools setup complete"
