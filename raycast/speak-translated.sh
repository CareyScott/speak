#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Translated
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon 🌍
# @raycast.description Translate the selected text with Claude, then read the translation aloud. English unless you type another language.
# @raycast.argument1 { "type": "text", "placeholder": "language (English)", "optional": true }

exec "$(dirname "$(readlink -f "$0")")/../bin/speak-translated" "$@"
