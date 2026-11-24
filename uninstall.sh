#!/usr/bin/env bash
# Omarsenal uninstaller. Removes only what Omarsenal added.
set -euo pipefail

OMARSENAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMARSENAL_ROOT
source "$OMARSENAL_ROOT/modules/lib.sh"

CATEGORIES=(foundation recon web exploitation passwords network ad blue workflow)

usage() {
  cat <<EOF
Usage: ./uninstall.sh [options]

  --config         Remove scripts, themes, keybinds and shell integration
  --<category>     Remove packages Omarsenal installed for that category
  --all            Everything above, for every category
  --dry-run        Print what would happen
  --yes            Assume yes to prompts

Packages that were already installed before Omarsenal are never removed.
The BlackArch repo stays configured. To remove it, delete the [blackarch]
section from /etc/pacman.conf and run: sudo pacman -Rns blackarch-keyring
Target folders are never touched.
EOF
}

remove_config=0
cats=()

[[ $# -eq 0 ]] && { usage; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) remove_config=1 ;;
    --all) remove_config=1; cats=("${CATEGORIES[@]}") ;;
    --dry-run) export DRY_RUN=1 ;;
    --yes) export ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    --*)
      c="${1#--}"
      [[ " ${CATEGORIES[*]} " == *" $c "* ]] || die "Unknown option: $1"
      cats+=("$c")
      ;;
    *) die "Unknown argument: $1" ;;
  esac
  shift
done

for c in "${cats[@]}"; do
  ledger="$OMARSENAL_STATE/installed-$c.txt"
  if [[ ! -s "$ledger" ]]; then
    info "[$c] nothing recorded, skipping"
    continue
  fi
  mapfile -t pkgs < <(while read -r p; do pacman -Qq "$p" &>/dev/null && echo "$p"; done < "$ledger")
  if ((${#pkgs[@]} == 0)); then
    info "[$c] recorded packages already gone"
  elif confirm "Remove ${#pkgs[@]} packages from $c (${pkgs[*]})?"; then
    run sudo pacman -Rns "${pkgs[@]}"
  else
    continue
  fi
  run rm -f "$ledger"
done

if [[ $remove_config == 1 ]]; then
  if [[ -x "$OMARSENAL_BIN/omarsenal-mode" ]]; then
    run "$OMARSENAL_BIN/omarsenal-mode" off || true
  fi

  info "Removing script links"
  for name in omarsenal-mode omarsenal-target omarsenal-scope omarsenal-workspace omarsenal-waybar; do
    run rm -f "$OMARSENAL_BIN/$name"
  done

  info "Removing theme links"
  for theme in "$OMARSENAL_ROOT"/themes/*/; do
    link="$HOME/.config/omarchy/themes/$(basename "$theme")"
    [[ -L "$link" ]] && run rm -f "$link"
  done

  info "Removing Hyprland and bash hooks"
  for f in "$HOME/.config/hypr/hyprland.conf" "$HOME/.bashrc"; do
    [[ -f "$f" ]] && run sed -i '/# omarsenal$/d' "$f"
  done

  info "Removing config links (your omarsenal.conf and state are kept)"
  for f in hypr.conf shell.sh tmux.conf; do
    run rm -f "$OMARSENAL_CONFIG/$f"
  done
fi

info "Uninstall complete"
