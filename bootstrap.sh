#!/usr/bin/env bash
set -euo pipefail

timestamp=$(date +%Y%m%d_%H%M%S)

GREEN="\033[1;32m"
RESET="\033[0m"

log() {
  echo -e "${GREEN}[*] $1${RESET}"
}

# check preconditions
require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ $1 required but not installed, abort."
    exit 1
  }
}

install_base_packages() {
  log "Update system and install basic tools..."
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y git curl ca-certificates gnupg lsb-release software-properties-common build-essential
}

configure_git() {
  log "Configuring git..."
  git config --global user.name "DudeNr33"
  git config --global user.email "3929834+DudeNr33@users.noreply.github.com"
  git config --global core.eof "lf"
  git config --global core.autocrlf "false"
}

install_zsh() {
  log "Install zsh..."
  [[ -d ~/.oh-my-zsh ]] && mv ~/.oh-my-zsh{,.bak_$timestamp}
  sudo apt install -y zsh
  if [[ "$SHELL" != "$(which zsh)" ]]; then
    log "Setting zsh as default shell for user $USER..."
    chsh -s "$(which zsh)"
  else
    log "Zsh already is the default shell for user $USER"
  fi
  log "Install Oh My Zsh..."
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_python() {
  log "Python: Install pip and venv..."
  sudo apt install -y python3 python3-pip python3-venv
  log "Python: install uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_node() {
  # install node also via apt so it can be picked up more easily by neovim
  log "Install node and nvm"
  sudo apt install -y nodejs
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
  # enable nvm command without having to reload the shell
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
  require_command nvm
  nvm install node
  nvm use node
}

install_neovim() {
  log "Install neovim and required dependencies..."
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  sudo apt update
  sudo apt install -y \
    neovim \
    ripgrep \
    fd-find \
    fzf \
    unzip \
    libpng-dev libjpeg-dev libtiff-dev imagemagick \
    ghostscript
  npm install -g @mermaid-js/mermaid-cli
  npm install -g @ast-grep/cli
  [[ -d ~/.config/nvim ]] && mv ~/.config/nvim{,.bak_$timestamp}
  [[ -d ~/.local/share/nvim ]] && mv ~/.local/share/nvim{,.bak_$timestamp}
  [[ -d ~/.local/state/nvim ]] && mv ~/.local/state/nvim{,.bak_$timestamp}
  [[ -d ~/.cache/nvim ]] && mv ~/.cache/nvim{,.bak_$timestamp}
  git clone https://github.com/DudeNr33/neovim-config.git ~/.config/nvim
  require_command uv
  (cd ~/.config/nvim && uv venv -p 3.13 && uv pip install pynvim)
}

main() {
  require_command curl
  install_base_packages
  configure_git
  install_zsh
  install_node
  install_python
  install_neovim

  log "✔  Bootstrap finished. Please restart the shell."
}

main
