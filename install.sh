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
  SETTINGS_APP="build/Speak Settings.app"
  rm -rf "$SETTINGS_APP"
  mkdir -p "$SETTINGS_APP/Contents/MacOS" "$SETTINGS_APP/Contents/Resources"
  cp macos/Settings/Info.plist "$SETTINGS_APP/Contents/Info.plist"
  cp macos/Settings/SpeakSettings.icns "$SETTINGS_APP/Contents/Resources/SpeakSettings.icns"
  swiftc -O -o "$SETTINGS_APP/Contents/MacOS/SpeakSettings" macos/Settings/*.swift macos/Shared/*.swift -framework AppKit -framework SwiftUI -framework Carbon
  codesign --force --sign - "$SETTINGS_APP" >/dev/null 2>&1
  swiftc -O -o build/SpeakHotkeys macos/Hotkeys/*.swift macos/Shared/*.swift -framework AppKit -framework Carbon
fi

claude mcp add --scope user speak -- node "$ROOT/dist/server.js"

mkdir -p "$CLAUDE_DIR/skills"
ln -sfn "$ROOT/skills/speak" "$CLAUDE_DIR/skills/speak"

mkdir -p "$HOME/.local/bin"
ln -sf "$ROOT/hooks/speak-auto" "$HOME/.local/bin/speak-auto"
ln -sf "$ROOT/dist/cli.js" "$HOME/.local/bin/speak"
for command in speak-selection speak-simply speak-translated speak-stop speak-settings speak-hotkeys; do
  ln -sf "$ROOT/bin/$command" "$HOME/.local/bin/$command"
done

if [ "$(uname)" = "Darwin" ]; then
  echo "Quick Actions:"
  bash "$ROOT/services/install-quick-actions.sh"
  bash "$ROOT/bin/speak-hotkeys" reload
fi

if [ -n "${RAYCAST_SCRIPTS_DIR:-}" ]; then
  mkdir -p "$RAYCAST_SCRIPTS_DIR"
  for script in "$ROOT"/raycast/speak-*.sh; do
    ln -sf "$script" "$RAYCAST_SCRIPTS_DIR/$(basename "$script")"
  done
  ln -sfn "$ROOT/raycast/speak-icons" "$RAYCAST_SCRIPTS_DIR/speak-icons"
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
  Settings:    speak-settings, or Speak Settings in Raycast (hotkeys, engine and voice, translation language, auto-speak)
  Quick Actions: right-click selected text > Services > Speak, Speak Simply, Speak Translated, Speak Stop (macOS)
  Raycast:     Speak Selection, Speak Simply, Speak Translated, Stop Speaking ($RAYCAST_NOTE)

Restart Claude Code, then try: "read that back to me simply".
MSG
