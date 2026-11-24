# Omarsenal shell integration. Sourced from ~/.bashrc by install.sh.
# Red and purple modes: scope-guarded nmap/masscan, session logging, prompt tag.

[[ $- == *i* ]] || return 0

_omarsenal_state="${XDG_STATE_HOME:-$HOME/.local/state}/omarsenal"
OMARSENAL_TARGETS="$HOME/omarsenal-targets"
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/omarsenal/omarsenal.conf" ]] && \
  source "${XDG_CONFIG_HOME:-$HOME/.config}/omarsenal/omarsenal.conf"
export OMARSENAL_TARGETS
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"

_omarsenal_mode()   { cat "$_omarsenal_state/mode" 2>/dev/null || echo off; }
_omarsenal_target() { cat "$_omarsenal_state/target" 2>/dev/null; }
_omarsenal_offensive() { case "$(_omarsenal_mode)" in red|purple) return 0 ;; esac; return 1; }

# Scope guard: refuse to run if any recognized target is outside scope.txt.
_omarsenal_guarded() {
  local tool="$1"; shift
  if _omarsenal_offensive; then
    omarsenal-scope args "$tool" "$@" || return 1
  fi
  command "$tool" "$@"
}
nmap()    { _omarsenal_guarded nmap "$@"; }
masscan() { _omarsenal_guarded masscan "$@"; }

# Prompt tag, e.g. [RED:acme]
_omarsenal_prompt() {
  local m t
  m="$(_omarsenal_mode)"
  [[ "$m" == off ]] && { _OMARSENAL_TAG=""; return; }
  t="$(_omarsenal_target)"
  _OMARSENAL_TAG="[${m^^}${t:+:$t}] "
}
PROMPT_COMMAND="_omarsenal_prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
[[ "$PS1" == *'$_OMARSENAL_TAG'* ]] || PS1='$_OMARSENAL_TAG'"$PS1"

# Session logging: wrap new terminals in `script` while red or purple is active.
if _omarsenal_offensive && [[ -z "${OMARSENAL_LOGGING:-}" ]] && command -v script >/dev/null; then
  _t="$(_omarsenal_target)"
  if [[ -n "$_t" && -d "$OMARSENAL_TARGETS/$_t/logs" ]]; then
    export OMARSENAL_LOGGING=1
    _log="$OMARSENAL_TARGETS/$_t/logs/$(date +%F_%H%M%S)-$$.log"
    echo "Omarsenal: logging this session to $_log"
    exec script -q -f "$_log"
  fi
  unset _t
fi
