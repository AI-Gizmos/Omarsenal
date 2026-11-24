#!/usr/bin/env bash
# Omarsenal installer. Layers a security toolkit on top of a stock Omarchy install.
set -euo pipefail

OMARSENAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMARSENAL_ROOT
source "$OMARSENAL_ROOT/modules/lib.sh"

CATEGORIES=(foundation recon web exploitation passwords network ad blue workflow)

usage() {
  cat <<EOF
Usage: ./install.sh [options]

Categories (pick any, or --all):
$(for c in "${CATEGORIES[@]}"; do printf '  --%s\n' "$c"; done)

Options:
  --all            Install every category
  --theme-only     Only install themes, keybinds, scripts and shell integration
  --no-blackarch   Do not add the BlackArch repo (only official repos and AUR)
  --dry-run        Print what would happen without changing anything
  --yes            Assume yes to prompts (AUR installs still list packages first)
  -h, --help       Show this help

Examples:
  ./install.sh --recon --web
  ./install.sh --all
  ./install.sh --theme-only
EOF
}

selected=()
theme_only=0
use_blackarch=1

[[ $# -eq 0 ]] && { usage; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) selected=("${CATEGORIES[@]}") ;;
    --theme-only) theme_only=1 ;;
    --no-blackarch) use_blackarch=0 ;;
    --dry-run) export DRY_RUN=1 ;;
    --yes) export ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    --*)
      cat="${1#--}"
      if [[ " ${CATEGORIES[*]} " == *" $cat "* ]]; then
        selected+=("$cat")
      else
        die "Unknown option: $1"
      fi
      ;;
    *) die "Unknown argument: $1" ;;
  esac
  shift
done

# Foundation is always needed for the scope guard, logging and labs.
if [[ $theme_only == 0 && ${#selected[@]} -gt 0 && " ${selected[*]} " != *" foundation "* ]]; then
  selected=(foundation "${selected[@]}")
fi

# --- Preflight -------------------------------------------------------------

[[ $EUID -eq 0 ]] && die "Run as your normal user, not root. sudo is used where needed."

if ! is_omarchy; then
  warn "Omarchy was not detected (~/.local/share/omarchy is missing)."
  confirm "Continue anyway on plain Arch?" || exit 1
fi

info "Omarsenal installs offensive security tools. Run it in a VM on an isolated network."
confirm "Have you taken a VM snapshot you can roll back to?" || die "Take a snapshot first, then rerun."

# --- Packages --------------------------------------------------------------

if [[ $theme_only == 0 ]]; then
  [[ $use_blackarch == 1 ]] && bash "$OMARSENAL_ROOT/modules/blackarch.sh"
  for cat in "${selected[@]}"; do
    bash "$OMARSENAL_ROOT/modules/install-category.sh" "$cat"
  done
  [[ " ${selected[*]} " == *" foundation "* ]] && bash "$OMARSENAL_ROOT/modules/docker.sh"
fi

# --- Integration -----------------------------------------------------------

info "Linking scripts into $OMARSENAL_BIN"
run mkdir -p "$OMARSENAL_BIN" "$OMARSENAL_CONFIG" "$OMARSENAL_STATE"
declare -A LINKS=(
  [omarsenal-mode]=scripts/ops-mode.sh
  [omarsenal-target]=scripts/target.sh
  [omarsenal-scope]=scripts/scope-check.py
  [omarsenal-workspace]=scripts/ops-workspace.sh
  [omarsenal-waybar]=config/waybar/omarsenal-waybar.sh
)
for name in "${!LINKS[@]}"; do
  run chmod +x "$OMARSENAL_ROOT/${LINKS[$name]}"
  run ln -sfn "$OMARSENAL_ROOT/${LINKS[$name]}" "$OMARSENAL_BIN/$name"
done

info "Linking config into $OMARSENAL_CONFIG"
run ln -sfn "$OMARSENAL_ROOT/config/hypr/omarsenal.conf" "$OMARSENAL_CONFIG/hypr.conf"
run ln -sfn "$OMARSENAL_ROOT/config/shell/omarsenal.sh" "$OMARSENAL_CONFIG/shell.sh"
run ln -sfn "$OMARSENAL_ROOT/config/tmux/tmux.conf" "$OMARSENAL_CONFIG/tmux.conf"
if [[ ! -f "$OMARSENAL_CONFIG/omarsenal.conf" ]]; then
  run cp "$OMARSENAL_ROOT/config/omarsenal.conf.example" "$OMARSENAL_CONFIG/omarsenal.conf"
fi

info "Installing themes"
themes_dir="$HOME/.config/omarchy/themes"
run mkdir -p "$themes_dir"
for theme in "$OMARSENAL_ROOT"/themes/*/; do
  name="$(basename "$theme")"
  run ln -sfn "${theme%/}" "$themes_dir/$name"
done

info "Hooking into Hyprland and bash"
append_once "source = ~/.config/omarsenal/hypr.conf # omarsenal" "$HOME/.config/hypr/hyprland.conf"
append_once '[[ -f ~/.config/omarsenal/shell.sh ]] && source ~/.config/omarsenal/shell.sh # omarsenal' "$HOME/.bashrc"

[[ -f "$OMARSENAL_STATE/mode" ]] || { [[ "$DRY_RUN" == 1 ]] || echo off > "$OMARSENAL_STATE/mode"; }

cat <<EOF

$(info "Install complete")

Next steps:
  1. Add the Waybar module: see config/waybar/README.md
  2. Create a target:       omarsenal-target new <name>
  3. Switch modes:          SUPER+ALT+R (red), B (blue), P (purple), O (off)
  4. Open a new terminal so the shell integration loads.

Read docs/safety.md before testing anything.
EOF
