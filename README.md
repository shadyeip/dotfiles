# dotfiles

Personal dotfiles with Catppuccin Mocha theme, Starship prompt, and tmux. Managed with [GNU Stow](https://www.gnu.org/software/stow/) — all configs live under `~/.config/`.

## What's Included

- **zsh** - Aliases, exports, PATH setup, plugins (autosuggestions, syntax highlighting, fzf)
- **tmux** - Catppuccin Mocha theme, tmux-yank, extrakto via TPM
- **starship** - Matching Catppuccin Mocha prompt
- **git** - Global config with common aliases
- **nvim** - Neovim with lazy.nvim, Catppuccin, and Treesitter
- **ghostty** - Terminal emulator config

## Structure

```
dotfiles/
├── git/.config/git/          # → ~/.config/git/
├── tmux/.config/tmux/        # → ~/.config/tmux/
├── nvim/.config/nvim/        # → ~/.config/nvim/
├── starship/.config/         # → ~/.config/starship.toml
├── ghostty/.config/ghostty/  # → ~/.config/ghostty/
├── zsh/.config/zsh/          # → ~/.config/zsh/
├── Brewfile                  # macOS packages
├── apt-packages.txt          # Linux packages
└── install.sh                # setup script
```

Each top-level directory is a stow package. Running `stow -t ~ git tmux nvim starship ghostty zsh` creates symlinks from `~/.config/` into the repo.

## Prerequisites

- zsh
- [GNU Stow](https://www.gnu.org/software/stow/)
- [Starship](https://starship.rs)
- tmux
- git

## Install

```sh
git clone https://github.com/shadyeip/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

On Linux with sudo:

```sh
sudo ./install.sh
```

The install script will:
1. Install dependencies (stow, starship, neovim, fzf, ripgrep, etc.)
2. Remove any old-style symlinks from a previous layout
3. Stow all packages to `~/.config/`
4. Prompt for your git identity (name/email) if not configured
5. Prompt for AI assistant selection (Claude/Gemini)
6. Install TPM and Treesitter parsers

After install, open tmux and press `prefix + I` to install tmux plugins.

For a detailed walkthrough of keybindings and vim motions, see [TUTORIAL.md](TUTORIAL.md).

## Update

Pull latest changes and verify installation:

```sh
dotup
```

This runs `git pull`, verifies symlinks and dependencies with `install.sh --verify`, and reloads your shell. Alias: `update_dotfiles`.

## Zsh Load Order

Files in `zsh/.config/zsh/` are sourced in alphabetical order via number prefixes:

1. `01-exports.zsh` — env vars, PATH
2. `02-plugins.zsh` — plugin auto-install + sourcing
3. `03-completions.zsh` — completion setup
4. `04-keybindings.zsh` — key bindings
5. `05-aliases.zsh` — aliases
6. `06-functions.zsh` — functions
7. `07-gcloud.zsh` — optional gcloud (conditional)

## Tmux Keybindings

### Splits

- `prefix -` — horizontal split
- `prefix |` — vertical split
- `prefix t` — open Claude in a split (if selected during install)
- `prefix g` — open Gemini in a split (if selected during install)

### Pane Sync

- `prefix s` — toggle synchronized input to all panes

### vim-tmux-navigator

- `Ctrl-h/j/k/l` — seamless navigation between vim splits and tmux panes

### tmux-yank

- Enter copy mode: `prefix + [`
- Select text (vi keys), then `y` to yank to clipboard

### tmux-resurrect

- `prefix + Ctrl-s` — save session
- `prefix + Ctrl-r` — restore session

### extrakto

- `prefix + tab` — fuzzy-find text from scrollback

## Zsh Plugins

Plugins are auto-installed on first shell load (cloned to `~/.config/zsh/plugins/`).

- **zsh-autosuggestions** — fish-like inline suggestions (right arrow to accept)
- **zsh-syntax-highlighting** — colorizes commands as you type
- **fzf integration** — `Ctrl-R` history, `Ctrl-T` file path, `Alt-C` cd

## Neovim

Leader key: `Space`

- `Space f` — find files
- `Space g` — live grep
- `Space b` — buffers
- `gd` — go to definition
- `gr` — references
- `K` — hover docs
- `Space r` — rename
- `Space F` — format buffer

Formatters: black, prettier, stylua, gofmt, terraform_fmt (auto-format on save).

LSP servers: pyright, gopls, lua_ls, ts_ls, terraformls (auto-installed via Mason).

## Git Config

Git identity is stored in `~/.config/git/config.local` (created by `install.sh`):

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```
