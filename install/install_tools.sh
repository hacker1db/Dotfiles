#!/bin/sh
if test ! $(which brew); then
    echo "Installing homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# cli tools
echo "Installing cli tools.."
brew tap caskroom/cask
brew tap homebrew/cask-fonts  
brew cask install font-dejavusansmono-nerd-font-mono
brew install git
brew install ack
brew install tree
brew install wget 
brew install fzf # Fuzzy file finder
brew install lnav # for viewing log files in terminal 
brew install az
echo "Installing tools for Chef dev"
# tools for chef dev
brew install packer
brew cask install vagrant
vagrant plugin install vagrant-cachier
brew cask install chefdk
brew install docker

# terminals cause why not!
brew install go
brew install hub
brew install reattach-to-user-namespace
brew install tmux
# installing pandoc and latex
brew install pandoc
brew cask install mactex
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
brew cask install powershell
brew cask install font-hack-nerd-font
brew install nmap 
echo "Installing neovim..."
# install neovim
brew install neovim

echo "Installing desktop application..."

brew cask install iterm2
brew cask install moom
brew cask install omnigraffle
brew cask install maltego
brew cask install spotify
brew cask install slack
brew cask install vmware-fusion
brew cask install virtualbox
brew cask install iterm2
brew cask install microsoft-office
brew cask install 1password
brew cask install private-internet-access
brew cask install torbrowser
brew cask install unetbootin
brew cask install soapui
brew cask install insomnia
brew cask install vlc
brew cask install alfred
brew cask install dash
brew cask install obs
brew cask install wireshark
brew cask install royal-tsx
echo "import the iterm dracula theme"
git clone https://github.com/dracula/iterm.git ~/.dotfiles/zsh/
echo "install deoplete requirements for neovim"
 pip3 install neovim
echo "Install jekyll for blogging"
sudo gem install jekyll bundler

exit 0
