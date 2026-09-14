#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Settings
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon speak-icons/speak-settings.png
# @raycast.description Set speak hotkeys, the engine and voice, the translation language and auto-speak
# @raycast.author Scott Carey
# @raycast.authorURL https://github.com/CareyScott

exec "$(dirname "$(readlink -f "$0")")/../bin/speak-settings"
