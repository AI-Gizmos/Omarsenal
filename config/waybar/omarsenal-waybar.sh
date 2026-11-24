#!/usr/bin/env bash
# Waybar custom module for Omarsenal. Prints JSON with the mode, target and live context.
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarsenal"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarsenal/omarsenal.conf"
VPN_INTERFACE="tun0"
SURICATA_FAST_LOG="/var/log/suricata/fast.log"
# shellcheck source=/dev/null
[[ -f "$CONF" ]] && source "$CONF"

mode="$(cat "$STATE/mode" 2>/dev/null || echo off)"
target="$(cat "$STATE/target" 2>/dev/null || true)"

vpn_ip() {
  ip -4 -o addr show "$VPN_INTERFACE" 2>/dev/null | awk '{print $4}' | cut -d/ -f1
}

alerts() {
  [[ -r "$SURICATA_FAST_LOG" ]] || { echo "?"; return; }
  grep -c "^$(date +%m/%d/%Y)" "$SURICATA_FAST_LOG" 2>/dev/null || echo 0
}

red_text()  { local ip; ip="$(vpn_ip)"; printf '%s %s' "${target:-no target}" "${ip:-no vpn}"; }
blue_text() { printf '%s alerts today' "$(alerts)"; }

case "$mode" in
  red)    text="RED · $(red_text)" ;;
  blue)   text="BLUE · $(blue_text)" ;;
  purple) text="PURPLE · $(red_text) · $(blue_text)" ;;
  *)      text="" ;;
esac

printf '{"text": "%s", "class": "%s", "tooltip": "Omarsenal mode: %s"}\n' "$text" "$mode" "$mode"
