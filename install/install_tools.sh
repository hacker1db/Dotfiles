#!/usr/bin/env bash

set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo Installing Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Backup installation for when brew bundle is unreliable

TAPS=(
  1password/tap
  anchore/grype
  anchore/syft
  aquasecurity/trivy
  arl/arl
  azure/functions
  azure/kubelogin
  brandonskerritt/rustscan
  caffix/amass
  cantino/mcfly
  dapr/tap
  dart-lang/dart
  derailed/k9s
  felixkratz/formulae
  fsouza/prettierd
  gitguardian/tap
  hashicorp/tap
  iina/mpv-iina
  jesseduffield/lazygit
  majd/repo
  mondoohq/mondoo
  noahgorstein/tap
  oven-sh/bun
  planetscale/tap
  rcmdnk/file
  robscott/tap
  sst/tap
  trufflesecurity/trufflehog
)

for tap in "${TAPS[@]}"; do
  brew tap "$tap" || true
done

FORMULAS=(
  ack
  act
  amass
  angular-cli
  azure-cli
  bat
  bat-extras
  eza
  fd
  fnm
  fzf
  gh
  git
  go
  grype
  highlight
  httpie
  hub
  hugo
  kubectx
  lazydocker
  lazygit
  lima
  lnav
  markdown
  mas
  mysql-client
  tree-sitter
  neovim
  nmap
  opencode
  pandoc
  reattach-to-user-namespace
  ripgrep
  rustscan
  shellcheck
  starship
  syft
  terraform-lsp
  tfenv
  tfsec
  tmux
  tree
  watch
  wget
  yaml-language-server
  yazi
  yq
  yt-dlp
  zoxide
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  oven-sh/bun/bun
)

for f in "${FORMULAS[@]}"; do
  brew install "$f" || true
done

CASKS=(
  1password
  1password-cli
  alfred
  android-platform-tools
  azure-data-studio
  basictex
  burp-suite-professional
  claude-code
  cursor
  dbeaver-community
  devtoys
  devtunnel
  discord
  drawio
  figma
  flutter
  flux-app
  font-cascadia-code
  font-caskaydia-cove-nerd-font
  font-dejavu-sans-mono-nerd-font
  font-hack-nerd-font
  font-jetbrains-mono
  font-jetbrains-mono-nerd-font
  font-monaspace
  font-monaspice-nerd-font
  font-symbols-only-nerd-font
  gcloud-cli
  ghostty
  gpg-suite-no-mail
  handbrake-app
  hiddenbar
  httpie-desktop
  iina
  karabiner-elements
  keycastr
  krisp
  kubecontext
  losslesscut
  menumeters
  microsoft-auto-update
  microsoft-azure-storage-explorer
  microsoft-edge
  microsoft-remote-desktop
  microsoft-teams
  netnewswire
  notion
  notion-calendar
  notion-mail
  obs
  obsidian
  podman-desktop
  postman
  powershell
  rancher
  raycast
  reader
  signal
  spotify
  todoist-app
  unetbootin
  visual-studio-code@insiders
  wireshark-app
  zap
  zen
  zoom
)

for c in "${CASKS[@]}"; do
  brew install --cask "$c" || true
done

# Fonts via tap already handled; ensure nerd fonts present
brew tap homebrew/cask-fonts || true

if command -v limactl >/dev/null 2>&1; then
  echo Starting lima default instance
  limactl start || true
fi

# Terraform setup
if command -v tfenv >/dev/null 2>&1; then
  tfenv install latest || true
  tfenv use latest || true
fi

# Node / JS toolchain
if command -v nvm >/dev/null 2>&1; then
  nvm install --lts || true
  nvm use --lts || true
fi

if command -v bun >/dev/null 2>&1; then
  npm install --global yarn || true
  yarn global add expo-cli || true
  bun i -g vercel || true
  bun install -g typescript typescript-language-server eslint prettier || true
fi

# Wordlists
if [ ! -d "$HOME/wordlists" ]; then
  git clone https://github.com/danielmiessler/SecLists.git "$HOME/wordlists" || true
fi

# Go tools
if command -v go >/dev/null 2>&1; then
  go install github.com/cosmtrek/air@latest || true
  go install github.com/charmbracelet/glow@latest || true
fi

# GitHub extensions
if command -v gh >/dev/null 2>&1; then
  gh auth login || true
  gh extension upgrade gh-copilot || true
  gh extension install dlvhdr/gh-dash || true
  gh extension install advanced-security/gh-sbom || true
fi

# MAS apps
if command -v mas >/dev/null 2>&1; then
  mas install 640199958 || true
  mas install 424389933 || true
  mas install 302584613 || true
  mas install 6445813049 || true
  mas install 497799835 || true
fi

echo Backup install complete
