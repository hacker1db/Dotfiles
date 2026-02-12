#!/usr/bin/env bash
# Install .NET SDKs and ASP.NET Core runtimes using Microsoft's official script
# Installs to ~/.dotnet and configures environment in ~/.zshrc

set -euo pipefail

DOTNET_ROOT="$HOME/.dotnet"
SHELL_CONFIG="$HOME/.zshrc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_BIN="$(dirname "$SCRIPT_DIR")/bin"

# .NET versions to install (LTS + Preview)
DOTNET_VERSIONS=("8.0" "10.0")

echo "Setting up .NET SDK and runtimes..."

# Create install directory
mkdir -p "$DOTNET_ROOT"

# Use local dotnet-install.sh from dotfiles/bin, or download if not found
if [ -x "$DOTFILES_BIN/dotnet-install.sh" ]; then
    INSTALL_SCRIPT="$DOTFILES_BIN/dotnet-install.sh"
    echo "Using dotnet-install.sh from $DOTFILES_BIN"
elif command -v dotnet-install.sh >/dev/null 2>&1; then
    INSTALL_SCRIPT="dotnet-install.sh"
    echo "Using dotnet-install.sh from PATH"
else
    INSTALL_SCRIPT=$(mktemp)
    echo "Downloading Microsoft dotnet-install.sh..."
    curl -fsSL "https://dot.net/v1/dotnet-install.sh" -o "$INSTALL_SCRIPT"
    chmod +x "$INSTALL_SCRIPT"
    DOWNLOADED=true
fi

# Install SDKs for each version
for version in "${DOTNET_VERSIONS[@]}"; do
    echo ""
    echo "Installing .NET SDK $version..."
    "$INSTALL_SCRIPT" --channel "$version" --install-dir "$DOTNET_ROOT" || {
        echo "Warning: Failed to install .NET SDK $version (may not be available yet)"
    }
done

# Install ASP.NET Core runtimes for each version
for version in "${DOTNET_VERSIONS[@]}"; do
    echo ""
    echo "Installing ASP.NET Core Runtime $version..."
    "$INSTALL_SCRIPT" --channel "$version" --runtime aspnetcore --install-dir "$DOTNET_ROOT" || {
        echo "Warning: Failed to install ASP.NET Core Runtime $version (may not be available yet)"
    }
done

# Clean up if we downloaded the script
[ "${DOWNLOADED:-}" = "true" ] && rm -f "$INSTALL_SCRIPT"

# Configure environment in shell config
echo ""
echo "Configuring environment..."

DOTNET_EXPORT_BLOCK='# .NET SDK
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"'

if [ -f "$SHELL_CONFIG" ]; then
    if grep -q 'DOTNET_ROOT' "$SHELL_CONFIG"; then
        echo "Environment already configured in $SHELL_CONFIG"
    else
        echo "" >> "$SHELL_CONFIG"
        echo "$DOTNET_EXPORT_BLOCK" >> "$SHELL_CONFIG"
        echo "Added DOTNET_ROOT and PATH to $SHELL_CONFIG"
    fi
else
    echo "$DOTNET_EXPORT_BLOCK" > "$SHELL_CONFIG"
    echo "Created $SHELL_CONFIG with DOTNET_ROOT and PATH"
fi

# Source for current session
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

# Verify installation
echo ""
echo "Installed SDKs:"
"$DOTNET_ROOT/dotnet" --list-sdks 2>/dev/null || echo "  (none found)"

echo ""
echo "Installed Runtimes:"
"$DOTNET_ROOT/dotnet" --list-runtimes 2>/dev/null || echo "  (none found)"

echo ""
echo ".NET setup complete"
echo "Run 'source ~/.zshrc' or start a new terminal to use dotnet"
