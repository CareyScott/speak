#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Speak Stop
# @raycast.mode silent
# @raycast.packageName Speak
# @raycast.icon ⏹️
# @raycast.description Stop the current reading

source "$(dirname "$(readlink -f "$0")")/lib.sh"

stop_reading
