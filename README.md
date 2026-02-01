# dotfiles2

Personal dotfiles with Catppuccin Mocha theme, Starship prompt, and tmux.

## What's Included

- **zsh** - Aliases, exports, PATH setup
- **tmux** - Catppuccin Mocha theme, tmux-yank, extrakto via TPM
- **starship** - Matching Catppuccin Mocha prompt
- **git** - Global config with common aliases

## Prerequisites

- zsh
- [Starship](https://starship.rs)
- tmux
- git

## Install

```sh
git clone https://github.com/youruser/dotfiles2.git ~/dev/dotfiles2
cd ~/dev/dotfiles2
chmod +x install.sh
./install.sh
```

After install, open tmux and press `prefix + I` to install tmux plugins.

## Tmux Plugins

### vim-tmux-navigator

Seamless navigation between vim splits and tmux panes using the same keys.

- `Ctrl-h` — move left
- `Ctrl-j` — move down
- `Ctrl-k` — move up
- `Ctrl-l` — move right

Requires the matching vim plugin ([vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)).

### tmux-yank

Copies text from tmux copy mode to the system clipboard.

- Enter copy mode: `prefix + [`
- Select text (vi keys), then press `y` to yank to system clipboard
- `prefix + y` copies the current command line to clipboard

### tmux-resurrect

Saves and restores tmux sessions (windows, panes, layouts) across system restarts.

- `prefix + Ctrl-s` — save the current session
- `prefix + Ctrl-r` — restore a previously saved session

### extrakto

Fuzzy-find and grab text from the scrollback buffer using fzf.

- `prefix + tab` opens the extrakto popup
- Type to filter URLs, paths, words, or other tokens from scrollback
- Press `enter` to insert the selection into the current pane, or `ctrl-y` to copy it

Create `~/.gitconfig.local` with your identity:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```
