#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Caffeinate
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon ☕️
# @raycast.packageName Dotfiles

# Documentation:
# @raycast.description Keep the Mac awake (caffeinate -isu). Runs until you stop it from Raycast.
# @raycast.author tom

set -euo pipefail

echo "☕️ Caffeinate is running (-isu)."
echo "Stop this script from Raycast to let the Mac sleep again."
exec caffeinate -isu
