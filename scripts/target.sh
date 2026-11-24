#!/usr/bin/env bash
# omarsenal-target: create and select target profiles.
#   omarsenal-target new <name>    create a profile folder
#   omarsenal-target use <name>    make it the active target
#   omarsenal-target current       print the active target and path
#   omarsenal-target list          list profiles
#   omarsenal-target check [name]  verify authorization and scope are filled in
set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarsenal"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarsenal/omarsenal.conf"
OMARSENAL_TARGETS="$HOME/omarsenal-targets"
# shellcheck source=/dev/null
[[ -f "$CONF" ]] && source "$CONF"
mkdir -p "$STATE" "$OMARSENAL_TARGETS"

die() { echo "error: $*" >&2; exit 1; }

valid_name() {
  [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] || die "Target names may only contain letters, numbers, dot, dash and underscore"
}

active() { cat "$STATE/target" 2>/dev/null || true; }

new_target() {
  local name="$1" dir="$OMARSENAL_TARGETS/$1"
  valid_name "$name"
  [[ -e "$dir" ]] && die "$dir already exists"

  mkdir -p "$dir"/{recon/{whois,dns,osint},scans/nmap,web,findings,logs,report}

  cat > "$dir/authorization.md" <<EOF
# Authorization: $name

Status: PENDING
<!-- Change to APPROVED only when you hold written permission to test. -->

- Approved by:
- Organization:
- Contact:
- Testing window (start / end):
- Reference (contract, SOW, email):
- Rules of engagement / restrictions:
EOF

  cat > "$dir/scope.txt" <<'EOF'
# In-scope targets, one per line.
#   10.0.0.0/24        CIDR
#   10.0.0.5           single IP
#   example.com        exact hostname
#   *.example.com      any subdomain of example.com
EOF

  cat > "$dir/out-of-scope.txt" <<'EOF'
# Out-of-scope targets. These override scope.txt. Same format.
EOF

  cat > "$dir/profile.md" <<EOF
# $name

Maintained by your agent from the raw output in this folder.

## Summary

## Key hosts

## Open services

## Findings so far

## Next steps
EOF

  printf 'hostname,ip,source,first_seen\n' > "$dir/recon/hosts.csv"
  printf 'ip,port,protocol,service,version,source\n' > "$dir/scans/services.csv"
  printf '# %s notes\n\n' "$name" > "$dir/notes.md"

  echo "Created $dir"
  echo "Fill in authorization.md and scope.txt, then run: omarsenal-target use $name"
}

check_target() {
  local name="${1:-$(active)}"
  [[ -n "$name" ]] || die "No target given and none active"
  local dir="$OMARSENAL_TARGETS/$name" ok=1
  [[ -d "$dir" ]] || die "No such target: $name"
  if ! grep -qE '^Status:[[:space:]]*APPROVED' "$dir/authorization.md" 2>/dev/null; then
    echo "authorization.md: Status is not APPROVED"; ok=0
  fi
  if ! grep -vE '^\s*(#|$)' "$dir/scope.txt" 2>/dev/null | grep -q .; then
    echo "scope.txt: no in-scope entries"; ok=0
  fi
  if [[ $ok == 1 ]]; then echo "$name is ready"; else return 1; fi
}

case "${1:-}" in
  new)     [[ -n "${2:-}" ]] || die "usage: omarsenal-target new <name>"; new_target "$2" ;;
  use)
    [[ -n "${2:-}" ]] || die "usage: omarsenal-target use <name>"
    valid_name "$2"
    [[ -d "$OMARSENAL_TARGETS/$2" ]] || die "No such target: $2"
    echo "$2" > "$STATE/target"
    pkill -RTMIN+8 waybar 2>/dev/null || true
    echo "Active target: $2"
    check_target "$2" || echo "Warning: target is not ready. Tools will be blocked by the scope guard." >&2
    ;;
  current)
    t="$(active)"
    [[ -n "$t" ]] && echo "$t  $OMARSENAL_TARGETS/$t" || echo "none"
    ;;
  list)    ls -1 "$OMARSENAL_TARGETS" ;;
  check)   check_target "${2:-}" ;;
  *)
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
