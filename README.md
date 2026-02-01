# dotfiles

Personal dotfiles with Catppuccin Mocha theme, Starship prompt, and tmux.

## What's Included

- **zsh** - Aliases, exports, PATH setup, plugins (autosuggestions, syntax highlighting, fzf)
- **tmux** - Catppuccin Mocha theme, tmux-yank, extrakto via TPM
- **starship** - Matching Catppuccin Mocha prompt
- **git** - Global config with common aliases
- **nvim** - Neovim with lazy.nvim, Catppuccin, and Treesitter
- **ghostty** - Terminal emulator config

## Prerequisites

- zsh
- [Starship](https://starship.rs)
- tmux
- git

## Install

```sh
git clone https://github.com/shadyeip/dotfiles.git ~/dotfiles
cd ~/dotfiles
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

## Zsh Plugins

Plugins are auto-installed on first shell load (cloned to `~/.zsh/plugins/`).

### zsh-autosuggestions

Suggests commands as you type based on your history. Press the right arrow key to accept a suggestion.

### zsh-syntax-highlighting

Highlights valid commands in green and invalid ones in red as you type, so you can catch typos before hitting enter.

### fzf integration

Fuzzy finder keybindings for zsh. Requires [fzf](https://github.com/junegunn/fzf) to be installed (handled by `install.sh`).

- `Ctrl-R` — fuzzy search command history
- `Ctrl-T` — fuzzy find and insert a file path
- `Alt-C` — fuzzy find and cd into a directory

## Neovim Plugins

### Treesitter

Provides language-aware syntax highlighting, indentation, and selection. Parsers are installed automatically when you open a file.

- `Ctrl-Space` — start/expand selection by syntax node (e.g. variable → expression → statement → function)
- `Backspace` — shrink selection back to the previous node
- `:TSInstallInfo` — list installed language parsers
- `:TSUpdate` — update all parsers

Pre-installed parsers: bash, c, css, dockerfile, go, html, javascript, json, lua, markdown, python, rust, terraform, toml, typescript, yaml. Other languages are installed on demand.

## Git Config

Create `~/.gitconfig.local` with your identity:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```
