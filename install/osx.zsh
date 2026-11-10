#!/usr/bin/env zsh
set -uo pipefail
source "${0:A:h}/lib.zsh"

if [[ "$OSTYPE" != darwin* ]]; then
    print "Skipping macOS setup: not running on macOS"
    exit 0
fi

title "Creating standard folders"
mkdir -p "$HOME/.vim-tmp" "$HOME/Developer" "$HOME/Developer/Sites" "$HOME/Screenshots"

title "Applying macOS preferences"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.Finder AppleShowAllFiles -bool true
defaults write com.apple.terminal StringEncodings -array 4
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
chflags nohidden ~/Library
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
defaults write NSGlobalDomain AppleFontSmoothing -int 2
defaults write com.apple.dock no-glass -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock itunes-notifications -bool true
defaults write com.apple.dock launchanim -bool true
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write NSGlobalDomain AppleShowScrollBars -string "Auto"
defaults write com.apple.finder DisableAllAnimations -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture location ~/Screenshots
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

title "Installing NvimTmux.app"
CLITOOLS="$(clitools_dir)"
APP_SOURCE="$CLITOOLS/NvimTmux.app"
APP_DEST="$HOME/Applications/NvimTmux.app"
BUNDLE_ID="dev.hacker1db.nvimtmux"
if [[ -d "$APP_SOURCE" ]]; then
    mkdir -p "$HOME/Applications"
    rm -rf "$APP_DEST"
    cp -R "$APP_SOURCE" "$APP_DEST"
    print "Installed NvimTmux.app to ~/Applications"
    /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$APP_DEST"
    if command -v duti >/dev/null 2>&1; then
        typeset -a file_types=(
            net.daringfireball.markdown public.plain-text public.json public.yaml
            public.shell-script public.source-code public.python-script public.ruby-script
            public.perl-script public.c-source public.c-header public.c-plus-plus-source
            public.swift-source public.html public.css com.netscape.javascript-source
            com.apple.property-list public.xml go rs ts tsx js jsx mjs cjs cs lua
            tf tfvars hcl dockerfile toml ini conf cfg env
        )
        typeset t
        for t in $file_types; do duti -s "$BUNDLE_ID" "$t" editor 2>/dev/null || true; done
        print "File associations configured for NvimTmux"
    else
        warning "duti not installed, skipping file associations"
    fi
else
    warning "NvimTmux.app not found at $APP_SOURCE, skipping"
fi

typeset app
for app in Safari Finder Dock Mail SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
success "macOS setup complete"
