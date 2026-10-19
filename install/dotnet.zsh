#!/usr/bin/env zsh
# .NET SDKs and ASP.NET Core runtimes in ~/.dotnet, plus global tools.
# PATH setup lives in zsh/zshrc.symlink; this script does not edit shell config.
set -uo pipefail
source "${0:A:h}/lib.zsh"

DOTNET_HOME="$HOME/.dotnet"
typeset -a versions=(8.0 10.0)

title "Installing .NET SDKs and runtimes"
mkdir -p "$DOTNET_HOME"

typeset install_script downloaded=""
if [[ -x "$DOTFILES/bin/dotnet-install.sh" ]]; then
    install_script="$DOTFILES/bin/dotnet-install.sh"
elif command -v dotnet-install.sh >/dev/null 2>&1; then
    install_script="dotnet-install.sh"
else
    install_script="$(mktemp)"
    print "Downloading Microsoft dotnet-install.sh..."
    curl --proto "=https" --tlsv1.2 -fsSL "https://dot.net/v1/dotnet-install.sh" -o "$install_script" ||
        { error "Could not download dotnet-install.sh"; exit 1 }
    chmod +x "$install_script"
    downloaded=1
fi

typeset version
for version in $versions; do
    print "\nInstalling .NET SDK $version..."
    "$install_script" --channel "$version" --install-dir "$DOTNET_HOME" ||
        warning "Failed to install .NET SDK $version (may not be available yet)"
    print "\nInstalling ASP.NET Core Runtime $version..."
    "$install_script" --channel "$version" --runtime aspnetcore --install-dir "$DOTNET_HOME" ||
        warning "Failed to install ASP.NET Core Runtime $version (may not be available yet)"
done
[[ -n "$downloaded" ]] && rm -f "$install_script"

title "Installing .NET global tools"
if ! command -v dotnet >/dev/null 2>&1; then
    export DOTNET_ROOT="$DOTNET_HOME"
    export PATH="$DOTNET_ROOT:$PATH"
fi
export PATH="$HOME/.dotnet/tools:$PATH"
if ! command -v dotnet >/dev/null 2>&1; then
    print "dotnet not found, skipping .NET global tools"
    exit 0
fi
typeset tool
for tool in csharp-ls; do
    dotnet tool update --global "$tool" || dotnet tool install --global "$tool"
done
success ".NET setup complete"
