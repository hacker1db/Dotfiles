#!/usr/bin/env bash

echo "Setting up extras"
mkdir -p "$HOME/.vim-tmp" "$HOME/Developer" "$HOME/Developer/Sites" "$HOME/Screenshots"
if [ -d "$HOME/Library/Application Support/rancher-desktop/lima" ] && [ ! -L "$HOME/Library/Application Support/rancher-desktop/lima" ]; then
  mv "$HOME/Library/Application Support/rancher-desktop/lima" "$HOME/.rdlima"
  ln -s "$HOME/.rdlima" "$HOME/Library/Application Support/rancher-desktop/lima"
fi
echo "Extras setup complete"