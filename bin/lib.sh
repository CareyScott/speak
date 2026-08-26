#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
SPEAK_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
SPEAK_CLI="$SPEAK_ROOT/dist/cli.js"

stop_reading() {
  pkill -f "$SPEAK_CLI" 2>/dev/null || true
}

input_text() {
  if [ ! -t 0 ]; then
    cat
    return 0
  fi
  selected_text
}

selected_text() {
  local saved
  saved="$(pbpaste 2>/dev/null || true)"
  osascript -e 'tell application "System Events" to keystroke "c" using command down' >/dev/null
  sleep 0.15
  local text
  text="$(pbpaste)"
  printf '%s' "$saved" | pbcopy
  if [ -z "$text" ] || [ "$text" = "$saved" ]; then
    echo "Nothing selected." >&2
    exit 1
  fi
  printf '%s' "$text"
}

language_code() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    german|deutsch) echo de ;;
    french|français) echo fr ;;
    spanish|español) echo es ;;
    italian|italiano) echo it ;;
    dutch|nederlands) echo nl ;;
    portuguese|português) echo pt ;;
    swedish|svenska) echo sv ;;
    danish|dansk) echo da ;;
    norwegian|norsk) echo nb ;;
    finnish|suomi) echo fi ;;
    polish|polski) echo pl ;;
    *) echo "" ;;
  esac
}

preferred_voices() {
  case "$1" in
    de) echo "Anna (Premium)|Petra (Premium)|Markus (Enhanced)|Viktor (Enhanced)|Helena (Enhanced)|Anna" ;;
    fr) echo "Amélie (Premium)|Thomas (Enhanced)|Audrey (Enhanced)|Aurélie (Enhanced)|Thomas" ;;
    es) echo "Mónica (Premium)|Jorge (Enhanced)|Paulina (Enhanced)|Marisol (Enhanced)|Mónica" ;;
    it) echo "Alice (Premium)|Luca (Enhanced)|Federica (Enhanced)|Alice" ;;
    nl) echo "Xander (Enhanced)|Claire (Enhanced)|Xander" ;;
    pt) echo "Joana (Premium)|Luciana (Enhanced)|Joana" ;;
    sv) echo "Alva (Premium)|Klara (Enhanced)|Alva" ;;
    da) echo "Sara (Premium)|Magnus (Enhanced)|Sara" ;;
    nb) echo "Nora (Premium)|Henrik (Enhanced)|Nora" ;;
    fi) echo "Satu (Enhanced)|Satu" ;;
    pl) echo "Zosia (Premium)|Krzysztof (Enhanced)|Zosia" ;;
    *) echo "" ;;
  esac
}

voice_for_language() {
  local code installed candidate
  code="$(language_code "$1")"
  [ -n "$code" ] || return 0
  installed="$(say -v '?' | awk -v code="$code" '{ line=$0; sub(/ +[a-z]{2}_[A-Z]{2} +#.*$/, "", line); if ($0 ~ " " code "_") print line }')"
  IFS='|' read -ra shortlist <<< "$(preferred_voices "$code")"
  for candidate in "${shortlist[@]}"; do
    if printf '%s\n' "$installed" | grep -qxF "$candidate"; then printf '%s' "$candidate"; return 0; fi
  done
  for tier in "(Premium)" "(Enhanced)"; do
    candidate="$(printf '%s\n' "$installed" | grep -F "$tier" | head -1)"
    if [ -n "$candidate" ]; then printf '%s' "$candidate"; return 0; fi
  done
  printf '%s\n' "$installed" | grep -v '(' | head -1
}

read_aloud() {
  stop_reading
  node "$SPEAK_CLI" <&0 >/dev/null 2>&1 &
}

read_aloud_in() {
  local voice
  voice="$(voice_for_language "$1")"
  stop_reading
  if [ -n "$voice" ]; then
    SPEAK_VOICE="$voice" node "$SPEAK_CLI" <&0 >/dev/null 2>&1 &
  else
    node "$SPEAK_CLI" <&0 >/dev/null 2>&1 &
  fi
}
