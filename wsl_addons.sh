#!/usr/bin/env bash
set -euo pipefail

symlink_xdg_open() {
  sudo apt remove -y xdg-utils
  sudo ln -s /mnt/c/Windows/explorer.exe /usr/local/bin/xdg-open
}

main() {
  symlink_xdg_open
}

main
