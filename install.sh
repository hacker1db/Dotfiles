#!/bin/bash

echo "Installing dotfiles!"

source install/link.sh

if [ "$(uname)" == "Darwin" ]; then
    echo "Running on OSX"
    echo "Brewing all the things"
    source install/install_tools.sh

    echo "Updating OSX settings"
    source install/osx.sh

    echo "Installing node (from nvm)"
    source install/nvm.sh
    fi
    
echo "creating vim directories"
mkdir -p ~/.vim-tmp
echo "Creating Sites, Code, Notes directories! :D Its the little things!" 
mkdir -p ~/Developer
mkdir -p ~/Developer/Sites
mkdir -p ~/.pandoc/templates
echo "Creating personalizable exports i.e for work duh..api keys?"
touch ~/.localrc
echo "set limactl to start up at login.."
limactl start-at-login

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Done."
