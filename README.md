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

### Splits

- `prefix -` — horizontal split
- `prefix |` — vertical split

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

Provides language-aware syntax highlighting, indentation, and selection. Unlike regex-based highlighting, Treesitter parses your code into a syntax tree so keywords, functions, variables, and strings are colored accurately.

Parsers are compiled during `install.sh` — nvim starts instantly with no compilation on launch.

- `Ctrl-Space` — start/expand selection by syntax node (e.g. variable → expression → statement → function)
- `Backspace` — shrink selection back to the previous node
- `:lua print(vim.treesitter.get_parser():lang())` — confirm Treesitter is active for the current file

Pre-installed parsers: bash, c, css, dockerfile, go, html, javascript, json, lua, markdown, python, rust, terraform, toml, typescript, yaml.

### Telescope

Fuzzy finder for files, text, buffers, and more. Opens a floating popup with live preview. Requires [ripgrep](https://github.com/BurntSushi/ripgrep) for live grep.

- `Space f` — find files by name
- `Space g` — live grep across all files
- `Space b` — switch between open buffers
- `Space h` — search Neovim help tags
- `Space gf` — find git-tracked files only
- `Space -` — horizontal split
- `Space |` — vertical split

Open a file with `:e path/to/file` — it stays loaded as a buffer even after you open another file. Use `Space b` to switch between all open buffers.

Inside the Telescope popup:
- Type to filter results
- `Ctrl-n` / `Ctrl-p` — move up/down
- `Enter` — open the selected file
- `Esc` — close the popup

### LSP (Language Server Protocol)

Provides go-to-definition, find references, hover docs, rename, diagnostics, and code actions. Language servers are installed automatically via [Mason](https://github.com/williamboman/mason.nvim) on first use.

Supported servers: pyright (Python), gopls (Go), lua_ls (Lua), ts_ls (TypeScript/JavaScript), terraformls (Terraform).

- `gd` — go to definition
- `gr` — find all references
- `K` — hover documentation
- `Space r` — rename symbol
- `Space a` — code actions
- `Space d` — show diagnostics for current line

### Auto-completion (nvim-cmp)

Completion popup appears automatically as you type. Sources: LSP suggestions, file paths, and buffer words.

- `Ctrl-n` / `Ctrl-p` — next/previous item
- `Enter` — confirm selection
- `Ctrl-Space` — manually trigger completion
- `Ctrl-d` / `Ctrl-u` — scroll docs

### General Keybindings

Leader key is `Space`. Pane navigation is handled by vim-tmux-navigator (`Ctrl-h/j/k/l`).

- `Space w` — save file
- `Space q` — quit
- `Space x` — close current buffer
- `Esc` — clear search highlight
- `J` / `K` (visual mode) — move selected lines down/up
- `<` / `>` (visual mode) — indent/outdent and keep selection
- `Ctrl-d` / `Ctrl-u` — half-page scroll and center cursor

## Git Config

Create `~/.gitconfig.local` with your identity:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```
