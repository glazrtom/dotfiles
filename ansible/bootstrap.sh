#!/usr/bin/env bash
# Bootstrap a fresh macOS machine: Homebrew, Ansible, a GitHub SSH key,
# a clone of this repo (with submodules), and Ansible's collections.
# Meant to be curl-able on a machine that doesn't have the repo yet:
#   curl -fsSL https://raw.githubusercontent.com/glazrtom/dotfiles/master/ansible/bootstrap.sh | bash
# Does NOT run any playbook — follow up with:
#   cd ~/dotfiles/ansible && ansible-playbook playbooks/init.yml -K
set -euo pipefail

DOTFILES_REPO="git@github.com:glazrtom/dotfiles.git"   # repo_dotfiles_ssh
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"          # path_dotfiles
SSH_KEY="$HOME/.ssh/id_ed25519"                         # ssh_key_path

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

# ---------------------------------------------------------------------------
# GitHub SSH identity — generate a key and wait for it to be added to GitHub
# if we're not already authenticated.
# ---------------------------------------------------------------------------
github_ssh_ok() {
  local out
  out="$(ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -T git@github.com 2>&1)" || true
  [[ "$out" == *"successfully authenticated"* ]]
}

if github_ssh_ok; then
  echo "GitHub SSH already authenticated."
else
  echo "GitHub SSH not authenticated yet."

  if [[ ! -f "$SSH_KEY" ]]; then
    echo "Generating a new SSH key..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -N "" -f "$SSH_KEY" -C "$(whoami)@$(hostname -s)"
  else
    echo "Using existing key at $SSH_KEY."
  fi

  echo
  echo "Add this public key to GitHub -> https://github.com/settings/keys"
  echo
  cat "$SSH_KEY.pub"
  echo
  read -r -p "Press ENTER once it is added to continue..." < /dev/tty

  if ! github_ssh_ok; then
    echo "GitHub SSH authentication still failing. Add the key above and re-run this script." >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Clone (or update) the dotfiles repo with all submodules.
# ---------------------------------------------------------------------------
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  echo "Updating existing clone at $DOTFILES_DIR..."
  git -C "$DOTFILES_DIR" pull --ff-only
  git -C "$DOTFILES_DIR" submodule update --init --recursive
elif [[ -e "$DOTFILES_DIR" ]]; then
  echo "$DOTFILES_DIR exists but is not a git repo. Move it aside and re-run this script." >&2
  exit 1
else
  echo "Cloning dotfiles with submodules into $DOTFILES_DIR..."
  git clone --recurse-submodules "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

echo "Installing Ansible collection requirements..."
ansible-galaxy collection install -r "$DOTFILES_DIR/ansible/requirements.yml"

echo "Bootstrap complete. Next:"
echo "  cd $DOTFILES_DIR/ansible && ansible-playbook playbooks/init.yml -K"
