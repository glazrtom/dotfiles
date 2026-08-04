#!/usr/bin/env bash
# Bootstrap a fresh macOS machine with Homebrew, Ansible, and its collections.
# Does NOT run any playbook — follow up with:
#   cd ansible && ansible-playbook playbooks/init.yml -K
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This bootstrap script only supports macOS." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed."
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Installing Ansible..."
  brew install ansible
else
  echo "Ansible already installed."
fi

echo "Installing Ansible collection requirements..."
ansible-galaxy collection install -r "$(dirname "$0")/requirements.yml"

echo "Bootstrap complete. Run 'ansible-playbook playbooks/init.yml -K' from the ansible directory when ready."
