#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Simply
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon 🗣️
# @raycast.description Rewrite the selected text as a plain spoken summary with Claude, then read it aloud

exec "$(dirname "$(readlink -f "$0")")/../bin/speak-simply"
