#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Translated
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon speak-icons/speak-translated.png
# @raycast.description Translate the selected text with Claude, then read the translation aloud
# @raycast.author Scott Carey
# @raycast.authorURL https://github.com/CareyScott
# @raycast.argument1 { "type": "dropdown", "placeholder": "Language", "optional": true, "data": [{ "title": "English", "value": "English" }, { "title": "German", "value": "German" }, { "title": "French", "value": "French" }, { "title": "Spanish", "value": "Spanish" }, { "title": "Italian", "value": "Italian" }, { "title": "Dutch", "value": "Dutch" }, { "title": "Portuguese", "value": "Portuguese" }, { "title": "Swedish", "value": "Swedish" }, { "title": "Danish", "value": "Danish" }, { "title": "Norwegian", "value": "Norwegian" }, { "title": "Finnish", "value": "Finnish" }, { "title": "Polish", "value": "Polish" }] }

source "$(dirname "$(readlink -f "$0")")/../bin/lib.sh"
language="$(translate_language "${1:-}")"

"$(dirname "$(readlink -f "$0")")/../bin/speak-translated" "$language" 2>&1 && echo "Reading in $language"
