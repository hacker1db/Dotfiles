#!/bin/sh
if test ! $(which brew); then
    echo "Installing homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# cli tools
echo "Installing cli tools.."
brew install gh
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
brew install --cask rancher
brew install kubectx
berw install helem
brew install lazygit # Git terminal UI
brew install --cask iina

# terminals cause why not!
brew install go
brew install hub
brew install reattach-to-user-namespace
brew install tmux
brew install terraform-lsp
brew install yaml-language-server
# installing pandoc and latex
brew install pandoc
brew cask install mactex
echo "installing tpm plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
brew install zsh
brew install highlight
brew install fnm
brew install z
brew install markdown
brew install node
brew install zsh-syntax-highlighting
brew install zsh-autosuggestions
brew install --cask powershell
echo "Install Azure powershell"
pwsh -c "Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force"
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
brew install --cask  font-Caskaydia-Cove-Nerd-Font
brew install nmap 
brew tap caffix/amass
brew install amass
brew install tree-sitter
brew install --cask dotnet
brew install --cask dotnet-sdk
dotnet tool install --global csharp-ls
brew install --cask flutter
brew install --cask hiddenbar
brew install --cask raycast
brew install --cask httpie
brew tap anchore/syft
brew install syft
brew tap azure/functions
brew install azure-functions-core-tools@4
# if upgrading on a machine that has 2.x or 3.x installed:
brew link --overwrite azure-functions-core-tools@4

echo "Installing neovim..."
# install neovim
brew install neovim

echo "Installing desktop application..."

brew install --cask wezterm
brew install --cask burp-suite-professional
brew install --cask darwio
brew install --cask spotify
brew install --cask slack
brew install --cask discord
brew install --cask 1password-cli
brew install --cask keycastr
brew install --cask jetbrains-toolbox
brew install --cask private-internet-access
brew install --cask unetbootin
brew install --cask soapui
brew install --cask obs
brew install --cask obsidian
brew install --cask wireshark
brew install rustscan
brew install --cask min
brew install --cask krisp
brew install --cask android-platform-tools
brew install planetscale/tap/pscale
brew install mysql-client
brew install yt-dlp
brew install --cask flux

echo "install yarn and tools"
npm install --global yarn
yarn global add prisma
yarn global add expo-cli
npm i -g vercel
npm install -g typescript typescript-language-server eslint prettier

brew install --cask menumeters
brew install --cask azure-data-studio
brew install --cask google-cloud-sdk
brew install kubectx
brew install --cask losslesscut
brew install watch
brew install tfsec
brew install tfenv


tfenv install latest
tfenv use latest

echo "set node version"
nvm use --lts
nvm install --lts 

echo "install wordlists"
git clone https://github.com/danielmiessler/SecLists.git ~/wordlists
echo "import the iterm dracula theme"
git clone https://github.com/dracula/iterm.git ~/.dotfiles/zsh/
echo "install deoplete requirements for neovim"
 pip3 install neovim
echo "Install tools for blogging"
brew install hugo
echo "go get your cli tools from github"

exit 0
