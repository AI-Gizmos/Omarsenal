#!/usr/bin/env bash
# omarsenal-mode: switch between red, blue, purple and off.
#   red     scope guard and session logging on, red theme
#   blue    detection services started, blue theme
#   purple  both, purple theme
#   off     everything stopped, previous theme restored
set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarsenal"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarsenal/omarsenal.conf"
mkdir -p "$STATE"

# Defaults, overridable in omarsenal.conf
BLUE_SERVICES="suricata.service"
WAYBAR_SIGNAL=8
# shellcheck source=/dev/null
[[ -f "$CONF" ]] && source "$CONF"

mode="${1:-status}"
current="$(cat "$STATE/mode" 2>/dev/null || echo off)"

notify() {
  command -v notify-send >/dev/null && notify-send -a Omarsenal "Omarsenal" "$1" || true
  echo "$1"
}

current_theme() {
  local dir="$HOME/.config/omarchy/current"
  if [[ -f "$dir/theme.name" ]]; then
    cat "$dir/theme.name"
  elif [[ -L "$dir/theme" ]]; then
    basename "$(readlink -f "$dir/theme")"
  fi
}

set_theme() {
  local theme="$1"
  [[ -z "$theme" ]] && return 0
  if ! command -v omarchy-theme-set >/dev/null; then
    echo "omarchy-theme-set not found, theme unchanged" >&2
    return 0
  fi
  omarchy-theme-set "$theme" >/dev/null 2>&1 || echo "Could not apply theme '$theme'" >&2
}

# systemctl without sudo asks polkit, which shows Omarchy's graphical auth prompt.
services() {
  local action="$1" svc
  for svc in $BLUE_SERVICES; do
    if systemctl cat "$svc" &>/dev/null; then
      systemctl "$action" "$svc" || echo "Could not $action $svc" >&2
    else
      echo "Service $svc not installed, skipping" >&2
    fi
  done
}

refresh_waybar() {
  pkill -RTMIN+"$WAYBAR_SIGNAL" waybar 2>/dev/null || true
}

enter_mode() {
  local new="$1" theme="$2" blue="$3"
  if [[ "$current" == off ]]; then
    current_theme > "$STATE/previous-theme" || true
  fi
  if [[ "$blue" == 1 ]]; then services start; else services stop; fi
  echo "$new" > "$STATE/mode"
  set_theme "$theme"
  refresh_waybar
}

case "$mode" in
  red)
    enter_mode red ops-red 0
    notify "RED mode: scope guard and logging active in new terminals"
    ;;
  blue)
    enter_mode blue ops-blue 1
    notify "BLUE mode: detection services started"
    ;;
  purple)
    enter_mode purple ops-purple 1
    notify "PURPLE mode: attack and detect"
    ;;
  off)
    services stop
    echo off > "$STATE/mode"
    set_theme "$(cat "$STATE/previous-theme" 2>/dev/null || true)"
    refresh_waybar
    notify "Ops mode off"
    ;;
  status)
    echo "mode:   $current"
    echo "target: $(cat "$STATE/target" 2>/dev/null || echo none)"
    ;;
  *)
    echo "Usage: omarsenal-mode red|blue|purple|off|status" >&2
    exit 1
    ;;
esac
