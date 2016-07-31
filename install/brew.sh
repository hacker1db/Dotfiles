#!/bin/sh

if test ! $(which brew); then
    echo "Installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Installing homebrew packages..."

# cli tools
brew install ack
brew install tree
brew install wget
#tools for chef dev
brew install packer
brew cask install virtualbox
brew cask install vagrant

# development server setup
brew install nginx
brew install dnsmasq

# development tools
brew install git
brew install hub
brew install macvim --override-system-vim
brew install reattach-to-user-namespace
brew install tmux
brew install zsh
brew install highlight
brew install nvm
brew install z
brew install earkdown
brew install node
# install neovim
brew install --HEAD  neovim/neovim/neovim

exit 0
