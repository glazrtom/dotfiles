#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Reload Dotfiles
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🔄
# @raycast.packageName Dotfiles

# Documentation:
# @raycast.description Pull the latest dotfiles and re-run the Ansible init playbook.
# @raycast.author tom

set -euo pipefail

cd ~/dotfiles
git pull --ff-only
cd ansible
ansible-playbook playbooks/init.yml -K
