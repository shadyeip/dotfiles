# dotfiles

Cross-platform zsh/tmux dotfiles for macOS and Linux.

## Install

```sh
git clone https://github.com/shadyeip/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

The installer will:
- Symlink `~/.zsh` and `~/.tmux.conf` to the repo
- Back up any existing files before overwriting
- Append a loader block to `~/.zshrc` if not already present

After install, optionally add these to your `~/.zshrc` (above the loader block):

```sh
export CUSTOM_HOSTNAME=""
export CUSTOM_USERNAME=""
```

## Update

```sh
dotfiles_update
# or
update_dotfiles
```

This runs `git pull` in the repo and reloads your shell.

## Tmux

Install TPM, then press `prefix + I` inside tmux to install plugins.

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Key Bindings

| Keys | Action |
|------|--------|
| `prefix + \|` | Split pane horizontally |
| `prefix + -` | Split pane vertically |
| `prefix + r` | Reload config |
| `prefix + tab` | Extrakto — fuzzy search screen text |
| `prefix + Ctrl-s` | Save session (resurrect) |
| `prefix + Ctrl-r` | Restore session (resurrect) |

### Extrakto (fuzzy text grabber)

Press `prefix + tab` to open a fuzzy finder over all text visible in your tmux pane. Use it to grab paths, URLs, command output, etc. without touching the mouse.

- `ctrl + f` — cycle filter modes (word / line / path / URL)
- `tab` — insert selection into the current pane
- `enter` — copy selection to clipboard
- `ctrl + o` — open selection (e.g. URL in browser)

Works over SSH since it runs inside tmux.

### Resurrect (session persistence)

Save and restore your tmux sessions across reboots.

- `prefix + Ctrl-s` — save all sessions, windows, and pane layouts
- `prefix + Ctrl-r` — restore previously saved sessions

Pane contents are captured automatically.

### Aliases

| Alias | Action |
|-------|--------|
| `work` | New/attach session "work" |
| `ss <name>` | New session |
| `sc <name>` | Attach to session |
| `sq <name>` | Kill session |
| `sls` | List sessions |

## Uninstall

```sh
rm ~/.zsh ~/.tmux.conf
```

Then remove the loader block from `~/.zshrc`.

## Supported Platforms

- macOS (Homebrew)
- Linux (Debian/Ubuntu, Fedora, etc.)
