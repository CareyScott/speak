#!/usr/bin/env bash
set -euo pipefail

FLAG="${SPEAK_AUTO_FLAG:-$HOME/.config/speak/auto}"
[ -f "$FLAG" ] || exit 0

INPUT="$(cat)"
ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')"
[ "$ACTIVE" = "true" ] && exit 0

STYLE="$(cat "$FLAG" 2>/dev/null | tr -d '[:space:]')"
STYLE="${STYLE:-brief}"

jq -n --arg style "$STYLE" '{
  decision: "block",
  reason: ("Auto-speak is on. Rewrite the answer you just gave as a spoken script in the \"" + $style + "\" style from the speak skill, call the speak MCP tool with it, then stop. Do not print the script. Reply with nothing but the word Speaking.")
}'
