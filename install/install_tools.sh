#!/bin/sh
if test ! $(which brew); then
    echo "Installing homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# cli tools
echo "Installing cli tools.."
brew tap caskroom/cask
brew tap homebrew/cask-fonts  
brew cask install font-dejavusansmono-nerd-font
brew install git
brew install ack
brew install tree
brew install wget 
brew install fzf # Fuzzy file finder
brew install lnav # for viewing log files in terminal 
brew install azure-cli
brew instal bat
brew install httpie
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
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
brew install nmap 
brew install tree-sitter
brew install --cask dotnet
brew install --cask dotnet-sdk
brew install --cask flutter
brew install --cask hiddenbar
brew tap anchore/syft
brew install syft

echo "Installing neovim..."
# install neovim
brew install neovim

echo "Installing desktop application..."

brew cask install iterm2
brew cask install moom
brew cask install darwio
brew cask install spotify
brew cask install slack
brew install --cask discord
brew cask install vmware-fusion
brew cask install virtualbox
brew cask install iterm2
brew install --cask 1password-cli
brew install --cask keycastr
brew install --cask jetbrains-toolbox
brew cask install private-internet-access
brew cask install torbrowser
brew cask install unetbootin
brew cask install soapui
brew cask install vlc
brew cask install alfred
brew cask install obs
brew install --cask obsidian
brew cask install wireshark
brew install rustscan
brew install --cask min
brew install --cask dotnet
brew install --cask krisp
brew install --cask postman
brew install --cask android-platform-tools
brew install planetscale/tap/pscale
brew install mysql-client


echo "import the iterm dracula theme"
git clone https://github.com/dracula/iterm.git ~/.dotfiles/zsh/
echo "install deoplete requirements for neovim"
 pip3 install neovim
echo "Install tools for blogging"
brew install hugo


exit 0
