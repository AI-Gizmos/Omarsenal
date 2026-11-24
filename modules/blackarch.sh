#!/usr/bin/env bash
# Add the BlackArch repository using the official strap.sh, with a manual checksum check.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if pacman-conf --repo-list 2>/dev/null | grep -qx blackarch; then
  info "BlackArch repo already configured"
  exit 0
fi

info "Adding the BlackArch repository"
if [[ "$DRY_RUN" == 1 ]]; then
  printf '  [dry-run] download https://blackarch.org/strap.sh, verify SHA1, run with sudo\n'
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL -o "$tmp/strap.sh" https://blackarch.org/strap.sh
echo
sha1sum "$tmp/strap.sh"
echo
info "Compare the SHA1 above with the one published at https://blackarch.org/downloads.html#install-repo"
confirm "Does the checksum match?" || die "Checksum not confirmed. BlackArch was not added."

chmod +x "$tmp/strap.sh"
sudo "$tmp/strap.sh"
sudo pacman -Sy
info "BlackArch repo added. Only the tools in your chosen categories will be installed, not the whole repo."
