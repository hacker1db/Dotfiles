#!/usr/bin/env bash

echo "Setting up extras"
mkdir -p "$HOME/.vim-tmp" "$HOME/Developer" "$HOME/Developer/Sites" "$HOME/Screenshots"
[ -f "$HOME/.localrc" ] || touch "$HOME/.localrc"
if command -v limactl >/dev/null 2>&1; then
  limactl start-at-login || echo "limactl start-at-login failed"
fi
if [ -d "$HOME/Library/Application Support/rancher-desktop/lima" ] && [ ! -L "$HOME/Library/Application Support/rancher-desktop/lima" ]; then
  mv "$HOME/Library/Application Support/rancher-desktop/lima" "$HOME/.rdlima"
  ln -s "$HOME/.rdlima" "$HOME/Library/Application Support/rancher-desktop/lima"
fi
echo "Extras setup complete"