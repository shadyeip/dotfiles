# dotfiles

Personal dotfiles with Catppuccin Mocha theme, Starship prompt, and tmux. Managed with [GNU Stow](https://www.gnu.org/software/stow/) — all configs live under `~/.config/`.

## What's Included

- **zsh** - Aliases, exports, PATH setup, plugins (autosuggestions, syntax highlighting, fzf)
- **tmux** - Catppuccin Mocha theme, tmux-yank, extrakto via TPM
- **starship** - Matching Catppuccin Mocha prompt
- **git** - Global config with common aliases
- **nvim** - Neovim with lazy.nvim, Catppuccin, and Treesitter
- **ghostty** - Terminal emulator config (macOS only — stowed on macOS hosts, skipped on Linux)

Ghostty is a GUI terminal emulator, so its config is only relevant on the
machine your terminal actually runs on. When you run `install.sh` on a Linux
box (e.g. a remote/SSH VM), the `ghostty` package is skipped automatically and
only the shell/editor configs are stowed.

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
├── install.sh                # setup script (installs packages + links configs)
└── install-macos-configs.sh  # macOS, configs only — no packages, no Homebrew
```

Each top-level directory is a stow package. On macOS, `install.sh` stows `git tmux nvim starship ghostty zsh`; on Linux it stows the same set minus `ghostty`. All create symlinks from `~/.config/` into the repo.

## Prerequisites

You need `git` and `curl` already installed to clone the repo and bootstrap.
`install.sh` installs everything else automatically on macOS and Debian/Ubuntu:

- zsh
- [GNU Stow](https://www.gnu.org/software/stow/)
- [Starship](https://starship.rs)
- Neovim
- fzf
- ripgrep
- gcc (Debian: `build-essential`) — for compiling Treesitter parsers
- Node.js + npm — for Neovim Mason LSP servers (pyright, ts_ls)
- Go — for Neovim Mason LSP servers (gopls)

The script does **not** install any AI assistant tooling, and it does **not**
install `git` (you already have it — you used it to clone this repo).

Privileged or system-wide steps (package installs, editing `/etc/shells`,
changing your login shell, running the downloaded Starship installer) prompt
for confirmation before running. Pass `--yes`/`-y` to accept all prompts for an
unattended install. Answering "no" to any prompt skips just that step.

If you prefer to install the dependencies manually first:

### macOS

Install Homebrew (if needed):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install prerequisites:

```sh
brew install zsh stow starship tmux neovim fzf ripgrep gcc node go
chsh -s "$(command -v zsh)"
```

Then log out and back in (or restart your terminal).

### Debian/Ubuntu

```sh
sudo apt update
sudo apt install -y zsh stow tmux neovim fzf ripgrep build-essential nodejs npm golang git curl
command -v zsh | sudo tee -a /etc/shells
chsh -s "$(command -v zsh)"
curl -sS https://starship.rs/install.sh | sh -s -- --yes
```

Then log out and back in (or restart your terminal).

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

For an unattended run that accepts all confirmation prompts:

```sh
./install.sh --yes
```

The install script will:
1. Install dependencies (stow, starship, neovim, fzf, ripgrep, Node.js/npm, Go, etc.) — asking before it installs anything system-wide
2. Remove any old-style symlinks from a previous layout (backing up anything with real content to `~/.dotfiles_backup/`)
3. Stow the packages to `~/.config/` (Ghostty only on macOS)
4. Set your default login shell to zsh (with confirmation)
5. Prompt for your git identity (name/email) if not configured
6. Install TPM and Treesitter parsers

No AI assistant tooling is installed.

### Host (macOS) vs. remote (Linux) machines

The same script works on both your Mac and a Linux box you SSH into:

- **On your Mac** (where the terminal runs): stows everything, including the
  Ghostty terminal config.
- **On a Linux VM** (remote/SSH target): stows the shell + editor configs
  (zsh, tmux, nvim, starship, git) and skips Ghostty, since there's no GUI
  terminal there.

Run `./install.sh` on each machine — it detects the OS and does the right thing.

After install, open tmux and press `prefix + I` to install tmux plugins.

### macOS without Homebrew (configs only)

On a locked-down Mac where you can't install Homebrew (e.g. a corporate
machine), use the config-only installer instead:

```sh
git clone https://github.com/shadyeip/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-macos-configs.sh
```

This links the same configs into `~/.config` and wires up `~/.zshrc`, but:

- Installs **no packages** and needs **no Homebrew** — it doesn't even require
  `stow` (it symlinks the configs directly).
- Doesn't change your login shell (macOS already defaults to zsh).
- Doesn't compile Neovim Treesitter parsers (that needs Neovim + a compiler).

The shell config degrades gracefully when a tool is missing, so you get a
working shell immediately. Install the individual tools (starship, tmux,
neovim, fzf, ripgrep, node, go) by whatever means your machine allows — a
self-service portal, or prebuilt binaries dropped into `~/.local/bin` — and
they light up on the next shell. zsh plugins auto-install on first shell load
(needs `git`, which ships with the Xcode Command Line Tools).

Re-run any time to repair links, and check them with:

```sh
./install-macos-configs.sh --verify
```

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

## Tmux Keybindings

### Splits

- `prefix -` — horizontal split
- `prefix |` — vertical split

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

The config uses the `vim.lsp.config` API, which requires **Neovim ≥ 0.11**. On
Linux, `install.sh` installs the official Neovim release rather than the (older)
apt package for this reason; on macOS Homebrew's Neovim is current.

## Remote coding over SSH

Neovim runs on the machine where you edit — so if you SSH from your Mac into a
Linux VM and run `nvim` there, the editor, its plugins, LSP servers and
Treesitter parsers all live on the VM. Run `install.sh` on the VM to set them
up (that's why it installs Node.js/Go/gcc there — Mason and the parsers need
them). LSP running next to your code means no round-trip latency on completion
and diagnostics.

Two things are handled so the remote experience matches local:

- **Clipboard** — the remote box has no `pbcopy`/`wl-copy`, so inside an SSH
  session Neovim routes the system registers through **OSC 52** escape
  sequences, which your local terminal turns into real clipboard operations.
  tmux is configured with `set-clipboard on` + `allow-passthrough on` so the
  escapes pass through, and Ghostty allows clipboard read/write. Yanks on the
  VM land in your Mac's clipboard.
- **Icons/fonts** — glyphs are drawn by the terminal on your *local* machine, so
  the Nerd Font only needs to be installed there (configured in the Mac-side
  `ghostty/config`), not on the VM.

## Git Config

Git identity is stored in `~/.config/git/config.local` (created by `install.sh`):

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```
