#!/usr/bin/env bash
# Enable Docker for the lab targets. Assumes the foundation category is installed.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

command -v docker >/dev/null || { warn "Docker not installed, skipping Docker setup"; exit 0; }

info "Enabling the Docker service"
run sudo systemctl enable --now docker.service

if id -nG "$USER" | grep -qw docker; then
  info "$USER is already in the docker group"
  exit 0
fi

warn "Membership in the docker group is equivalent to root access."
if confirm "Add $USER to the docker group so labs run without sudo?"; then
  run sudo usermod -aG docker "$USER"
  info "Log out and back in for the group change to apply."
else
  info "Skipped. Use sudo with docker compose instead."
fi
