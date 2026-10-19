#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/env.sh"

if ! load_brew_env; then
  echo Installing Homebrew
  /bin/bash -c "$(curl --proto "=https" --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew_env || { echo "Homebrew installed but brew is not on PATH" >&2; exit 1; }
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
  gitguardian/tap
  hashicorp/tap
  iina/mpv-iina
  jesseduffield/lazygit
  majd/repo
  mondoohq/mondoo
  noahgorstein/tap
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
  dotnet
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
  jq
  kubectx
  lazydocker
  lazygit
  lima
  lnav
  markdown
  mysql-client
  tree-sitter
  tree-sitter-cli
  neovim
  nmap
  opencode
  pandoc
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
  pnpm
)

if [[ "$(uname -s)" == Darwin ]]; then
  FORMULAS+=(
    mas
    reattach-to-user-namespace
  )
fi

for f in "${FORMULAS[@]}"; do
  brew install "$f" || true
done

CASKS=(
  1password
  1password-cli
  alfred
  android-platform-tools
  basictex
  burp-suite-professional
  claude
  codex
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

if [[ "$(uname -s)" == Darwin ]]; then
  for c in "${CASKS[@]}"; do
    brew install --cask "$c" || true
  done
  # Fonts via tap already handled; ensure nerd fonts present
  brew tap homebrew/cask-fonts || true
fi

# Claude Code comes from the native installer (auto-updates in ~/.local/bin); the claude cask is the desktop app.
[ -x "$HOME/.local/bin/claude" ] || curl --proto "=https" --tlsv1.2 -fsSL https://claude.ai/install.sh | bash || true

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

if command -v pnpm >/dev/null 2>&1; then
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
  mkdir -p "$PNPM_HOME"
  export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"
  npm install --global --ignore-scripts yarn || true
  yarn global add expo-cli || true
  pnpm add --global vercel || true
  pnpm add --global typescript typescript-language-server eslint prettier @github/copilot || true
fi

# Wordlists
if [ ! -d "$HOME/wordlists" ]; then
  git clone https://github.com/danielmiessler/SecLists.git "$HOME/wordlists" || true
fi

# Go tools
if command -v go >/dev/null 2>&1; then
  go install github.com/cosmtrek/air@latest || true
  go install github.com/charmbracelet/glow@latest || true
  (cd "$(dirname "${BASH_SOURCE[0]}")/.." && GOBIN="$HOME/.local/bin" go install ./cmd/...) || true
fi

# GitHub extensions
if command -v gh >/dev/null 2>&1; then
  gh auth status >/dev/null 2>&1 || gh auth login || true
  gh extension install dlvhdr/gh-dash || true
  gh extension install advanced-security/gh-sbom || true
  gh extension install github/gh-stack || true
fi

# MAS apps
if [[ "$(uname -s)" == Darwin ]] && command -v mas >/dev/null 2>&1; then
  mas install 640199958 || true
  mas install 424389933 || true
  mas install 302584613 || true
  mas install 6445813049 || true
  mas install 497799835 || true
fi

echo Backup install complete

bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/verify.sh"
