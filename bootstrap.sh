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
  sudo apt install -y git curl ca-certificates gnupg lsb-release software-properties-common build-essential xdg-utils
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
  log "Install tmux..."
  sudo apt install -y tmux
  cp .zshrc ~/.zshrc
}

install_python() {
  log "Python: Install pip and venv..."
  sudo apt install -y python3 python3-pip python3-venv
  log "Python: install uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  source $HOME/.local/bin/env
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

install_java() {
  log "Install Java JDK"
  wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg &&
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
  sudo apt update
  sudo apt install -y java-21-amazon-corretto-jdk
}

install_neovim() {
  if [[ -z "${SKIP_NVIM:-}" ]]; then
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
  else
    log "Skipping neovim installation (SKIP_NVIM is set)"
  fi
}

install_docker() {
  log "Install Docker..."
  # Remove possibly existing old installations
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt remove -y $pkg; done

  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt update

  # Install docker packages
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # add user to docker group
  if ! getent group docker >/dev/null; then
    sudo groupadd docker
  fi
  sudo usermod -aG docker $USER
}

install_k8s_tools() {
  log "Install kind (Kubernetes-in-Docker)..."
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind

  log "Install kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl*

  log "Install KubeVela..."
  curl -fsSl https://kubevela.io/script/install.sh | bash
}

main() {
  require_command curl
  install_base_packages
  configure_git
  install_zsh
  install_node
  install_python
  install_java
  install_neovim
  install_docker
  install_k8s_tools

  log "✔  Bootstrap finished. Please restart the shell."
}

main
