#!/usr/bin/env bash
set -euo pipefail

symlink_xdg_open() {
  sudo apt remove -y xdg-utils
  sudo ln -s /mnt/c/Windows/explorer.exe /usr/local/bin/xdg-open
}

fix_docker() {
  # docker does not work with nftables
  # https://forums.docker.com/t/failing-to-start-dockerd-failed-to-create-nat-chain-docker/78269
  sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
  sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
}

main() {
  symlink_xdg_open
  fix_docker
}

main
