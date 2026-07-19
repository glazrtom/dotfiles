# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal cross-platform dotfiles for macOS and Arch/Debian Linux. Config directories (`alacritty/`, `nvim/`, `ranger/`, `rofi/`, `polybar/`, `i3/`, `zsh/`, etc.) hold app configs; two systems deploy them: Ansible (`ansible/`, preferred/current) and a legacy bash installer (`setup/`). Many configs and shell plugins are pulled in as git submodules (see `.gitmodules`) — after cloning, run `git submodule update --init --recursive`.

## Deployment

### Ansible (`ansible/`) — preferred
One playbook per tool, symlinking `~/dotfiles/<tool>` into `~` or `~/.config` (`file: state=link force=yes`) after installing the relevant package. Path variables (`path_home`, `path_config`, `path_local`, `path_dotfiles`) come from `group_vars/all.yml` — reuse them rather than hardcoding paths.

```
cd ~/dotfiles/ansible
ansible-playbook -i inventory.ini playbooks/bundle/base.yml -l local -K
```

- `playbooks/bundle/base.yml` — core bundle: imports `dotfiles.yml` (clones the repo to `~/dotfiles`) → `zsh.yml` → `nvim.yml` → `ranger.yml`.
- `playbooks/core/config_dir.yml` — shared helper ensuring `~/.config` exists.
- `playbooks/server/` — homelab (`orangePi`) provisioning: `k3s.yml` (k3s, MetalLB, ArgoCD, cloudflared, SealedSecrets), `k3s_apps.yml`, `server/init/init.yml` (first-boot user/hostname setup, own inventory). Several server playbooks use `vars_prompt` for secrets.
- Hosts: `inventory.ini` has `[server]` (orangePi) and `[local]` (localhost) groups.
- **Add a new tool**: create `ansible/playbooks/<tool>.yml` following the install-then-symlink pattern and wire it into `bundle/base.yml`.

### Bash installer (`setup/`) — legacy, still used for granular/interactive scripts
Entry point `setup/setup.sh`, exposed as the `setup` zsh function (tab-completes over `setup/scripts/`):
- `setup <script.sh> [more.sh ...]` — run named scripts from `setup/scripts/`
- `setup` with no args — opens a rofi multi-select menu (Linux only)
- `setup/batch/` holds bundles, e.g. `setup/batch/server.sh` runs `setup_zsh.sh setup_nvim.sh setup_ranger.sh`

`setup.sh` sources `variables.sh`, `messages.sh`, `functions.sh` (which sources `functions_install.sh`), runs `pre_setup.sh` to detect the package manager (brew / pacman / apt), then executes each selected script. Scripts follow a naming convention: `install_*` (packages), `setup_*` (configure a tool), `link_*` (symlink config). Shared helpers in `functions.sh`: `link()`/`sudo_link()`, `file_add_content`/`file_remove_content`, `check`/`check_and_dd`, `confirm`. OS/paths are exported by `variables.sh` (`IS_MAC`, `IS_DEBIAN_BASED`, `IS_ARCH_BASED`, `DOTFILES_*`).

## Shell (zsh is primary)

- `zsh/.zshrc` is the main config; it sources `zsh/zsh_alias` for **all** aliases/functions — put new shell customizations in `zsh_alias`, not `.zshrc`. Edit shortcuts: `zshrc` / `zshalias` aliases.
- No plugin manager: plugins are either system packages installed via Ansible (zsh-autosuggestions, zsh-syntax-highlighting, autojump) or vendored as git submodules under `zsh/` (`powerlevel10k/`, `zsh-history-substring-search/`).
- `exa` replaces `ls` (`ls`/`ll`/`lt`), `nvim` is `$EDITOR`, git aliases `g`/`ga`/`gc`/`gh`(checkout)/`gA`(amend)/`gd`/`gl`/`gp`/`gs`/`gf`, `k`=kubectl.
- Equivalent functions also exist for fish under `fish/functions/` if that shell needs updating too.

### Git worktree workflow (custom functions in `zsh/zsh_alias`)
- `gwc <branch>` — create/switch to a worktree at `<repo>.worktrees/<branch>`. Handles local/remote/new branches (with completion), offers to transfer uncommitted changes via stash, and copies untracked project files (`.idea/workspace.xml`, `secrets.properties`, `local.properties`, `*.local*`).
- `git_clean_gone` — delete local branches whose upstream is gone, removing any attached worktree.
- `git_clean_wt_nochange` — remove `.worktrees/` worktrees with no uncommitted changes and no unpushed commits, then delete their branches.

Both cleanup functions report reclaimed disk size and prompt before deleting.
