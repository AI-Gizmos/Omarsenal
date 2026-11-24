#!/usr/bin/env bash
# shellcheck disable=SC2034  # variables are used by the scripts that source this file
# Shared helpers for Omarsenal scripts. Source this file, do not execute it.

OMARSENAL_ROOT="${OMARSENAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OMARSENAL_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarsenal"
OMARSENAL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarsenal"
OMARSENAL_BIN="$HOME/.local/bin"
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"

info() { printf '\033[1;31m[omarsenal]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# Run a command, or just print it in dry-run mode.
run() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

confirm() {
  [[ "$ASSUME_YES" == 1 ]] && return 0
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# Print package names from a list file, ignoring comments and blank lines.
read_list() {
  sed 's/#.*//' "$1" | awk 'NF {print $1}'
}

is_omarchy() {
  [[ -d "$HOME/.local/share/omarchy" ]]
}

# Append a line to a file once. Lines are tagged so uninstall can find them.
append_once() {
  local line="$1" file="$2"
  [[ -f "$file" ]] || run touch "$file"
  if ! grep -qxF "$line" "$file" 2>/dev/null; then
    if [[ "$DRY_RUN" == 1 ]]; then
      printf '  [dry-run] append to %s: %s\n' "$file" "$line"
    else
      printf '%s\n' "$line" >> "$file"
    fi
  fi
}
