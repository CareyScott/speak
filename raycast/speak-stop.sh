#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Stop Speaking
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon speak-icons/speak-stop.png
# @raycast.description Stop the current reading
# @raycast.author Scott Carey
# @raycast.authorURL https://github.com/CareyScott

"$(dirname "$(readlink -f "$0")")/../bin/speak-stop" 2>&1 && echo "Stopped"
