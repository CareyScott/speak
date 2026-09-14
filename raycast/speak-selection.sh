#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Selection
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon speak-icons/speak.png
# @raycast.description Read the selected text aloud as written
# @raycast.author Scott Carey
# @raycast.authorURL https://github.com/CareyScott

"$(dirname "$(readlink -f "$0")")/../bin/speak-selection" 2>&1 && echo "Reading aloud"
