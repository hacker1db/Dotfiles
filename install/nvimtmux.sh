#!/usr/bin/env bash
# NvimTmux App Installer - Opens files in Neovim inside tmux via Ghostty

CLITOOLS="$HOME/Developer/clitools"
APP_SOURCE="$CLITOOLS/NvimTmux.app"
APP_DEST="$HOME/Applications/NvimTmux.app"
BUNDLE_ID="dev.hacker1db.nvimtmux"

echo "Setting up NvimTmux..."

# Install app to ~/Applications
if [ -d "$APP_SOURCE" ]; then
    mkdir -p "$HOME/Applications"
    rm -rf "$APP_DEST"
    cp -R "$APP_SOURCE" "$APP_DEST"
    echo "Installed NvimTmux.app to ~/Applications"
    
    # Register with LaunchServices
    /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$APP_DEST"
    echo "Registered with LaunchServices"
else
    echo "Warning: NvimTmux.app not found at $APP_SOURCE"
    exit 1
fi

# Set default editor associations with duti
if command -v duti >/dev/null 2>&1; then
    echo "Setting file associations..."
    
    # Text/Markdown
    duti -s "$BUNDLE_ID" net.daringfireball.markdown editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.plain-text editor 2>/dev/null
    
    # Data formats
    duti -s "$BUNDLE_ID" public.json editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.yaml editor 2>/dev/null
    
    # Shell/Scripts
    duti -s "$BUNDLE_ID" public.shell-script editor 2>/dev/null
    
    # Source code
    duti -s "$BUNDLE_ID" public.source-code editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.python-script editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.ruby-script editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.perl-script editor 2>/dev/null
    
    # C/C++/Swift
    duti -s "$BUNDLE_ID" public.c-source editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.c-header editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.c-plus-plus-source editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.swift-source editor 2>/dev/null
    
    # Go (by extension - no built-in UTI)
    duti -s "$BUNDLE_ID" go editor 2>/dev/null
    
    # Rust (by extension - no built-in UTI)
    duti -s "$BUNDLE_ID" rs editor 2>/dev/null
    
    # TypeScript (by extension - no built-in UTI)
    duti -s "$BUNDLE_ID" ts editor 2>/dev/null
    duti -s "$BUNDLE_ID" tsx editor 2>/dev/null
    
    # JavaScript extensions
    duti -s "$BUNDLE_ID" js editor 2>/dev/null
    duti -s "$BUNDLE_ID" jsx editor 2>/dev/null
    duti -s "$BUNDLE_ID" mjs editor 2>/dev/null
    duti -s "$BUNDLE_ID" cjs editor 2>/dev/null
    
    # C# (by extension - no built-in UTI)
    duti -s "$BUNDLE_ID" cs editor 2>/dev/null
    
    # Lua (by extension - no built-in UTI)
    duti -s "$BUNDLE_ID" lua editor 2>/dev/null
    
    # Terraform/HCL (by extension)
    duti -s "$BUNDLE_ID" tf editor 2>/dev/null
    duti -s "$BUNDLE_ID" tfvars editor 2>/dev/null
    duti -s "$BUNDLE_ID" hcl editor 2>/dev/null
    
    # Docker
    duti -s "$BUNDLE_ID" dockerfile editor 2>/dev/null
    
    # Config files (by extension)
    duti -s "$BUNDLE_ID" toml editor 2>/dev/null
    duti -s "$BUNDLE_ID" ini editor 2>/dev/null
    duti -s "$BUNDLE_ID" conf editor 2>/dev/null
    duti -s "$BUNDLE_ID" cfg editor 2>/dev/null
    duti -s "$BUNDLE_ID" env editor 2>/dev/null
    
    # Web
    duti -s "$BUNDLE_ID" public.html editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.css editor 2>/dev/null
    duti -s "$BUNDLE_ID" com.netscape.javascript-source editor 2>/dev/null
    
    # Config files
    duti -s "$BUNDLE_ID" com.apple.property-list editor 2>/dev/null
    duti -s "$BUNDLE_ID" public.xml editor 2>/dev/null
    
    echo "File associations configured"
else
    echo "Warning: duti not installed, skipping file associations"
fi

echo "NvimTmux setup complete"
