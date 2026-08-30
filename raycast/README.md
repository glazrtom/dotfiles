# Raycast

Raycast keeps almost no plain-text config: settings live in an encrypted
SQLite database (`~/Library/Application Support/com.raycast.macos/raycast-enc.sqlite`)
and the rest is machine state in `~/Library/Preferences/com.raycast.macos.plist`
(onboarding flags, analytics IDs, window-position cache — nothing worth
tracking, and it's rewritten wholesale by `cfprefsd` so a symlink would break).
None of that is managed here.

What *is* tracked:

## `scripts/` — Script Commands

Symlinked by `roles/raycast` to `~/.config/raycast/scripts`. Each file is a
shell script with a Raycast header block, e.g. `scripts/reload-dotfiles.sh`:

```bash
#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title My Command
# @raycast.mode compact
# @raycast.packageName Dotfiles
```

Requirements:
- The file must be executable (`chmod +x`).
- `schemaVersion`, `title`, and `mode` (`compact` or `fullOutput`) are required;
  `icon`, `packageName`, `description`, `author` etc. are optional.
- See the [Script Commands docs](https://github.com/raycast/script-commands) for
  the full header reference.

**One-time manual step per machine** (Raycast stores this path in its encrypted
DB, so Ansible can't set it): Raycast → Settings → Extensions → Script Commands →
*Add Script Directory* → `~/.config/raycast/scripts`.

## Extensions

`ansible/roles/raycast/vars/main.yml` records the store extensions currently
installed (`owner/name`). The role diffs that list against
`~/.config/raycast/extensions` and reports anything missing — Raycast has no
install CLI, so installing is still a manual click on the store page. Set
`raycast_open_extension_deeplinks: true` (in your own inventory/host vars) to
have the role open a `raycast://extensions/<owner>/<name>` tab for each missing
one automatically.

## `.rayconfig` backup (not committed)

Raycast → Settings → Advanced → *Export Settings & Data* produces a
`.rayconfig` file with your quicklinks, snippets, aliases, hotkeys, and
extension preferences (which can include API keys, e.g. the Spotify extension's
tokens). This dotfiles repo is **public**, so no `.rayconfig` is committed here
— `raycast/*.rayconfig` is gitignored on purpose.

To back yours up, export it manually and store it somewhere private (a
password manager, a private repo, encrypted disk backup). To restore: Raycast →
Settings → Advanced → *Import Settings & Data* → pick the file. This step is
entirely manual; Ansible cannot apply it.
