#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon 🔊
# @raycast.description Read the selected text aloud as written

exec "$(dirname "$(readlink -f "$0")")/../bin/speak-selection"
