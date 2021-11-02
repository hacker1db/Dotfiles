#!/bin/bash

echo "Installing dotfiles"

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
echo "Creating Sites, Code, Chef, Notes directories! :D Its the little things!" 
mkdir -p ~/Code
mkdir -p ~/Code/Sites
echo "Creating personalizable exports i.e for work duh..api keys?"
touch ~/.localrc


echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Done."
