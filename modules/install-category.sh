#!/usr/bin/env bash
# Install one package category from packages/<category>.txt.
# Order of preference: official repos and BlackArch (via pacman), then AUR (via yay, with confirmation).
# Only packages Omarsenal actually installed are recorded, so uninstall never removes
# anything that was already on the system.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

category="${1:?usage: install-category.sh <category>}"
list="$OMARSENAL_ROOT/packages/$category.txt"
[[ -f "$list" ]] || die "Unknown category: $category"

mkdir -p "$OMARSENAL_STATE"
ledger="$OMARSENAL_STATE/installed-$category.txt"
touch "$ledger"

repo_pkgs=()
aur_pkgs=()

while read -r pkg; do
  if pacman -Qq "$pkg" &>/dev/null; then
    info "$pkg already installed, skipping"
    continue
  fi
  if pacman -Si "$pkg" &>/dev/null; then
    repo_pkgs+=("$pkg")
  elif command -v yay >/dev/null && yay -Si "$pkg" &>/dev/null; then
    aur_pkgs+=("$pkg")
  else
    warn "$pkg not found in repos or AUR, skipping"
  fi
done < <(read_list "$list")

record() {
  [[ "$DRY_RUN" == 1 ]] && return 0
  printf '%s\n' "$@" >> "$ledger"
  sort -u "$ledger" -o "$ledger"
}

if ((${#repo_pkgs[@]})); then
  info "[$category] repo packages: ${repo_pkgs[*]}"
  run sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}"
  record "${repo_pkgs[@]}"
fi

if ((${#aur_pkgs[@]})); then
  warn "[$category] these come from the AUR (community build scripts): ${aur_pkgs[*]}"
  warn "Review each PKGBUILD at https://aur.archlinux.org before continuing."
  if confirm "Install AUR packages for $category?"; then
    run yay -S --needed "${aur_pkgs[@]}"
    record "${aur_pkgs[@]}"
  else
    warn "Skipped AUR packages for $category"
  fi
fi

info "[$category] done"
