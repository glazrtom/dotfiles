# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal cross-platform dotfiles for macOS and Arch/Debian Linux. Config directories (`alacritty/`, `nvim/`, `ranger/`, `rofi/`, `polybar/`, `i3/`, `zsh/`, etc.) hold app configs; two systems deploy them: Ansible (`ansible/`, preferred/current) and a legacy bash installer (`setup/`). Many configs and shell plugins are pulled in as git submodules (see `.gitmodules`) — after cloning, run `git submodule update --init --recursive`.

## Deployment

### Ansible (`ansible/`) — preferred
Flat roles + thin orchestration playbooks for **desktop workstation configs only**. Each tool is a role that installs its package then symlinks `~/dotfiles/<tool>` into `~` or `~/.config` (`file: state=link force=yes`). Path variables (`path_home`, `path_config`, `path_local`, `path_dotfiles`) come from `group_vars/all.yml` — reuse them rather than hardcoding paths. `ansible.cfg` sets `roles_path = roles` and the default inventory, so `-i` is not needed.

On a brand-new mac without the repo yet, `ansible/bootstrap.sh` is the curl-able entry point — it installs Homebrew + Ansible, bootstraps a GitHub SSH key (printing the pubkey and waiting for you to add it), clones `dotfiles` with submodules into `~/dotfiles`, then installs the collections below. The manual steps are only needed when the repo is already present:

```
cd ~/dotfiles/ansible
ansible-galaxy collection install -r requirements.yml   # first time / fresh host
ansible-playbook playbooks/init.yml -K
```

- **Layout**: `roles/*` hold task logic; `playbooks/*` are thin entry points. Roles pull dependencies via `meta/main.yml` (e.g. `zsh`→`fastfetch`, `nvim`/`ranger`→`config_dir`). Tunables live in each role's `defaults/main.yml`.
- `playbooks/init.yml` — core bundle: `system_update` → `dotfiles` (clone/update) → `zsh` → `nvim` → `ranger` → `alacritty`. Run individually via `playbooks/<tool>.yml`. Prompt-bearing tools (`git`, `docker`) keep a thin playbook because `vars_prompt` is play-level only. Homebrew itself is installed only by `ansible/bootstrap.sh` (not a role) — playbooks assume `brew` is already on `PATH` on macOS.
- **Transport for dotfiles**: `dotfiles_transport` (`group_vars/all.yml`) is `ssh` — clones everything incl. private submodules, bootstraps an SSH key.
- Hosts: single `inventory.ini` with just `[local]` (localhost).
- **Add a new tool**: create `roles/<tool>/` (tasks + optional `defaults`/`meta`) and either wire it into `playbooks/init.yml` or give it a thin `playbooks/<tool>.yml`.
- **Server/homelab provisioning** (k3s, MetalLB, ArgoCD, etc.) moved to the `homelab` repo — see `~/projects/homelab/ansible` (`playbooks/main.yml`).
- **`playbooks/claude.yml`** installs Claude Code, ccstatusline, and `cpm` (claude-profile-manager), then symlinks `claude/settings.json` → `~/.claude/settings.json` and `claude/ccstatusline/settings.json` → `~/.config/ccstatusline/settings.json`. `~/.claude` must stay a real directory (Claude writes ~100M+ of transcripts/cache/credentials into it) — only individual files are linked into it, never the directory itself. Only these two config files are tracked; everything else under `~/.claude` (history, credentials, daemon state, plugin cache, projects) is machine state and stays untracked.
- **`roles/vscode`** installs VS Code (Homebrew cask on macOS — the first cask user in this repo; Microsoft's apt repo on Debian/Ubuntu; `extra/code` via pacman on Arch, which is the OSS/Open-VSX build) and symlinks `vscode/settings.json` + `vscode/keybindings.json` into the OS-specific VS Code user dir (`~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux). It also installs the extension list from `roles/vscode/vars/main.yml` via `code --install-extension`. Only those two config files are tracked; the rest of the user dir is machine state.
- **`playbooks/dev_tools.yml`** is the developer-tooling bundle: `claude` + `vscode` + `ranger` in one run. Meant to be run after `playbooks/init.yml`.
- **`roles/alacritty`** installs Alacritty (Homebrew cask on macOS; `package:` on Linux) and the Hack Nerd Font it requires (cask `font-hack-nerd-font` on macOS, `ttf-hack-nerd` via pacman on Arch, downloaded from the Nerd Fonts GitHub release into `~/.local/share/fonts` on Debian/Ubuntu since no apt package exists), then symlinks `alacritty/` → `~/.config/alacritty`.

### Bash installer (`setup/`) — legacy, still used for granular/interactive scripts
Entry point `setup/setup.sh`, exposed as the `setup` zsh function (tab-completes over `setup/scripts/`):
- `setup <script.sh> [more.sh ...]` — run named scripts from `setup/scripts/`
- `setup` with no args — opens a rofi multi-select menu (Linux only)
- `setup/batch/` holds bundles, e.g. `setup/batch/server.sh` runs `setup_zsh.sh setup_nvim.sh setup_ranger.sh`

`setup.sh` sources `variables.sh`, `messages.sh`, `functions.sh` (which sources `functions_install.sh`), runs `pre_setup.sh` to detect the package manager (brew / pacman / apt), then executes each selected script. Scripts follow a naming convention: `install_*` (packages), `setup_*` (configure a tool), `link_*` (symlink config). Shared helpers in `functions.sh`: `link()`/`sudo_link()`, `file_add_content`/`file_remove_content`, `check`/`check_and_dd`, `confirm`. OS/paths are exported by `variables.sh` (`IS_MAC`, `IS_DEBIAN_BASED`, `IS_ARCH_BASED`, `DOTFILES_*`).

## Shell (zsh is primary)

- `zsh/.zshrc` is the main config; it sources `zsh/zsh_alias` for **all** aliases/functions — put new shell customizations in `zsh_alias`, not `.zshrc`. Edit shortcuts: `zshrc` / `zshalias` aliases.
- No plugin manager: plugins are either system packages installed via Ansible (zsh-autosuggestions, zsh-syntax-highlighting, autojump) or vendored as git submodules under `zsh/` (`powerlevel10k/`, `zsh-history-substring-search/`).
- `eza` replaces `ls` (`ls`/`ll`/`lt`), `nvim` is `$EDITOR`, git aliases `g`/`ga`/`gc`/`gh`(checkout)/`gA`(amend)/`gd`/`gl`/`gp`/`gs`/`gf`, `k`=kubectl.
- Equivalent functions also exist for fish under `fish/functions/` if that shell needs updating too.

### Git worktree workflow (custom functions in `zsh/zsh_alias`)
- `gwc <branch>` — create/switch to a worktree at `<repo>.worktrees/<branch>`. Handles local/remote/new branches (with completion), offers to transfer uncommitted changes via stash, and copies untracked project files (`.idea/workspace.xml`, `secrets.properties`, `local.properties`, `*.local*`).
- `git_clean_gone` — delete local branches whose upstream is gone, removing any attached worktree.
- `git_clean_wt_nochange` — remove `.worktrees/` worktrees with no uncommitted changes and no unpushed commits, then delete their branches.

Both cleanup functions report reclaimed disk size and prompt before deleting.
