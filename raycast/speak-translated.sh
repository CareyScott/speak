#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Translated
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon 🌍
# @raycast.description Translate the selected text with Claude, then read the translation aloud. English unless you type another language.
# @raycast.argument1 { "type": "text", "placeholder": "language (English)", "optional": true }

source "$(dirname "$(readlink -f "$0")")/lib.sh"

LANGUAGE="${1:-${SPEAK_TRANSLATE_LANGUAGE:-English}}"
PROMPT="Translate the following text into $LANGUAGE for listening, not reading. Keep the meaning and tone, keep names as they are, and use plain natural $LANGUAGE. Read links and emails as spoken (example dot com slash login). Output only the translation."

selected_text | claude -p "$PROMPT" --output-format text | read_aloud
