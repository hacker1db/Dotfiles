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
    
    echo "Configuring nginx"
    # create a backup of the original nginx.conf
    mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.original
    ln -s ~/.dotfiles/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf
    # symlink the code.dev from dotfiles
    ln -s ~/.dotfiles/nginx/code.dev /usr/local/etc/nginx/sites-enabled/code.dev
    fi
    
echo "creating vim directories"
mkdir -p ~/.vim-tmp
echo "Creating Sites, Code, Chef, Notes directories! :D Its the little things!" 
mkdir -p ~/Documents/Code
mkdir -p ~/Documents/Code/Sites
mkdir -p ~/Documents/Code/Chef_Projects
mkdir -p ~/Documents/Notes
echo "Creating personalizable exports i.e for work duh..api keys?"
touch ~/.localrc



echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Done."
