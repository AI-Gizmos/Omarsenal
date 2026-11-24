#!/usr/bin/env bash
# omarsenal-workspace: open the ops layout on a dedicated workspace.
# Terminal in the active target folder, plus Burp (red/purple) and notes.
set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarsenal"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarsenal/omarsenal.conf"
OMARSENAL_TARGETS="$HOME/omarsenal-targets"
OPS_WORKSPACE=9
# shellcheck source=/dev/null
[[ -f "$CONF" ]] && source "$CONF"

mode="$(cat "$STATE/mode" 2>/dev/null || echo off)"
target="$(cat "$STATE/target" 2>/dev/null || true)"
dir="$HOME"
[[ -n "$target" && -d "$OMARSENAL_TARGETS/$target" ]] && dir="$OMARSENAL_TARGETS/$target"

launch() { setsid -f "$@" >/dev/null 2>&1 || true; }

hyprctl dispatch workspace "$OPS_WORKSPACE" >/dev/null

if command -v xdg-terminal-exec >/dev/null; then
  launch xdg-terminal-exec --dir="$dir"
else
  launch alacritty --working-directory "$dir"
fi

if [[ "$mode" == red || "$mode" == purple ]] && command -v burpsuite >/dev/null; then
  launch burpsuite
fi

if command -v obsidian >/dev/null; then
  launch obsidian
fi
