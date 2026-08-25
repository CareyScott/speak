#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Simply
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon 🗣️
# @raycast.description Rewrite the selected text as a plain spoken summary with Claude, then read it aloud

source "$(dirname "$(readlink -f "$0")")/lib.sh"

PROMPT='Rewrite the following text as a short spoken script for listening, not reading. Plain words, no jargon, short sentences, under 120 words. Start with the point. Read links and emails as spoken (example dot com slash login), spelling short endings letter by letter (dot d e, dot i o). Respell words with two readings so a voice cannot misread them: live as lyive when it means running, read in the past tense as red. Output only the script.'

selected_text | claude -p "$PROMPT" --output-format text | read_aloud
