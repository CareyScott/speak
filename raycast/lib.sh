#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
SPEAK_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
SPEAK_CLI="$SPEAK_ROOT/dist/cli.js"

stop_reading() {
  pkill -f "$SPEAK_CLI" 2>/dev/null || true
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

read_aloud() {
  local text
  text="$(cat)"
  stop_reading
  node "$SPEAK_CLI" "$text" >/dev/null 2>&1 &
}
