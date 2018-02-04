#!/bin/sh

if test ! $(which brew); then
    echo "Installing homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# cli tools
echo "Installing cli tools.."
brew tap caskroom/cask
brew install git
brew install ack
brew install tree
brew install wget 
brew install fzf # Fuzzy file finder
brew install lnav # for viewing log files in terminal 
echo "Install jekyll for blogging"
gem install jekyll bundler
echo "Installing tools for Chef dev"
# tools for chef dev
brew install packer
brew cask install vagrant
vagrant plugin install vagrant-cachier
brew cask install chefdk
brew install docker

# terminals cause why not!
brew install hub
brew install reattach-to-user-namespace
brew install tmux
echo "installing tpm plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
brew install zsh
brew install highlight
brew install nvm
brew install z
brew install markdown
brew install node
brew install zsh-syntax-highlighting
brew install zsh-autosuggestions
brew install nmap 
echo "Installing neovim..."
# install neovim
brew install neovim

echo "Installing desktop application..."

brew cask install iterm2
brew cask install moom
brew cask install google-chrome
brew cask install spotify
brew cask install slack
brew cask install vmware-fusion
brew cask install visual-studio-code
brew cask install virtualbox
brew cask install iterm2
brew cask install microsoft-office
brew cask install 1password
brew cask install torbrowser
brew cask install unetbootin
brew cask install owasp-zap
brew cask install soapui
brew cask install vlc
brew cask install polymail
brew cask install alfred
brew cask install foxitreader
brew cask install dash

exit 0
