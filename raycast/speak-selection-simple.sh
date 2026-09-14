#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Simply
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon speak-icons/speak-simply.png
# @raycast.description Rewrite the selected text as a short plain script with Claude, then read it aloud
# @raycast.author Scott Carey
# @raycast.authorURL https://github.com/CareyScott

"$(dirname "$(readlink -f "$0")")/../bin/speak-simply" 2>&1 && echo "Reading the simple version"
