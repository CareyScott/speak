#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

command -v jq >/dev/null || { echo "jq is required (brew install jq)"; exit 1; }

cd "$ROOT"
npm install
npm run build
chmod +x dist/server.js dist/cli.js

if [ "$(uname)" = "Darwin" ] && command -v swiftc >/dev/null; then
  swiftc -O -o overlay/SpeakOverlay overlay/main.swift -framework AppKit -framework AVFoundation
fi

claude mcp add --scope user speak -- node "$ROOT/dist/server.js"

mkdir -p "$CLAUDE_DIR/skills"
ln -sfn "$ROOT/skills/speak" "$CLAUDE_DIR/skills/speak"

mkdir -p "$HOME/.local/bin"
ln -sf "$ROOT/hooks/speak-auto" "$HOME/.local/bin/speak-auto"
ln -sf "$ROOT/dist/cli.js" "$HOME/.local/bin/speak"
for command in speak-selection speak-simply speak-translated speak-stop; do
  ln -sf "$ROOT/bin/$command" "$HOME/.local/bin/$command"
done

if [ "$(uname)" = "Darwin" ]; then
  echo "Quick Actions:"
  bash "$ROOT/services/install-quick-actions.sh"
fi

if [ -n "${RAYCAST_SCRIPTS_DIR:-}" ]; then
  mkdir -p "$RAYCAST_SCRIPTS_DIR"
  for script in "$ROOT"/raycast/speak-*.sh; do
    ln -sf "$script" "$RAYCAST_SCRIPTS_DIR/$(basename "$script")"
  done
  RAYCAST_NOTE="linked into $RAYCAST_SCRIPTS_DIR"
else
  RAYCAST_NOTE="add $ROOT/raycast as a Script Directory in Raycast (Settings > Extensions > Script Commands), or rerun with RAYCAST_SCRIPTS_DIR=<dir>"
fi

SETTINGS="$CLAUDE_DIR/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
HOOK_CMD="$ROOT/hooks/auto-speak.sh"
if ! grep -q "$HOOK_CMD" "$SETTINGS"; then
  TMP="$(mktemp)"
  jq --arg cmd "$HOOK_CMD" '.hooks.Stop = ((.hooks.Stop // []) + [{hooks: [{type: "command", command: $cmd}]}])' "$SETTINGS" > "$TMP"
  mv "$TMP" "$SETTINGS"
fi

cat <<MSG

Installed.
  MCP server:  speak (user scope)
  Skill:       /speak [simple|brief|decisions|full|eli5]
  Auto-speak:  speak-auto on|off|status   (off by default)
  CLI:         echo "hello" | speak
  Commands:    speak-selection, speak-simply, speak-translated [language], speak-stop
  Quick Actions: right-click selected text > Services > Speak, Speak Simply, Speak Translated, Speak Stop (macOS)
  Raycast:     Speak, Speak Simply, Speak Translated, Speak Stop ($RAYCAST_NOTE)

Restart Claude Code, then try: "read that back to me simply".
MSG
