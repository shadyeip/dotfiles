# dotfiles

Personal dotfiles for a consistent shell/terminal environment across a macOS
host and several Linux servers reached over SSH. Managed with
[GNU Stow](https://www.gnu.org/software/stow/) — all configs live under
`~/.config/` (plus `~/.zshrc`) as plain symlinks into this repo.

**This repo installs nothing.** There is no install script and no automated
package management. It only contains config files and a Stow layout. Every
tool it assumes (zsh, tmux, oh-my-zsh, Stow itself, ...) is something you
install yourself, once, by hand — see [Prerequisites](#prerequisites) below.

## What's Included

- **zsh** - oh-my-zsh based shell config: exports, completions, keybindings,
  aliases, functions
- **tmux** - Catppuccin Mocha theme, vi-style copy mode, OSC 52 clipboard
  passthrough for SSH sessions
- **git** - global config with common aliases
- **ghostty** - terminal emulator config (macOS only — the GUI terminal runs
  on your Mac, not on a remote box, so this package is only meaningful there)

## Structure

```
dotfiles/
├── zsh/.zshrc                 # → ~/.zshrc
├── zsh/.config/zsh/           # → ~/.config/zsh/  (loaded by .zshrc)
├── tmux/.config/tmux/         # → ~/.config/tmux/
├── git/.config/git/           # → ~/.config/git/
├── ghostty/.config/ghostty/   # → ~/.config/ghostty/
├── README.md
└── TUTORIAL.md
```

Each top-level directory is a Stow package. Stowing mirrors the package's
internal path structure onto `$HOME`, so `zsh/.zshrc` becomes `~/.zshrc` and
`zsh/.config/zsh/01-exports.zsh` becomes `~/.config/zsh/01-exports.zsh`.

## Prerequisites

Install these yourself, on whichever machine needs them. Nothing here is run
automatically — copy the command you need.

### Required everywhere

- **git** and **zsh**
  - macOS: `brew install git zsh`
  - Debian/Ubuntu: `sudo apt install git zsh`
- **GNU Stow** (used to symlink this repo into `$HOME`)
  - macOS: `brew install stow`
  - Debian/Ubuntu: `sudo apt install stow`
- **[oh-my-zsh](https://ohmyz.sh/)** — the zsh config assumes it's installed
  at `~/.oh-my-zsh`:
  ```sh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
  ```
  `--keep-zshrc` stops the installer from overwriting the `~/.zshrc` this
  repo provides; stow it after installing oh-my-zsh (or re-stow with `-R` if
  you stowed first).
- **zsh-autosuggestions** and **zsh-syntax-highlighting** (referenced by
  `plugins=(...)` in `zsh/.zshrc`; oh-my-zsh looks for them under its custom
  plugins directory):
  ```sh
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  ```
- **tmux**
  - macOS: `brew install tmux`
  - Debian/Ubuntu: `sudo apt install tmux`
- **[TPM](https://github.com/tmux-plugins/tpm)** (tmux plugin manager):
  ```sh
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```
  After stowing the `tmux` package and starting tmux, press `prefix + I` to
  install the plugins listed in `tmux.conf`.
- **[Catppuccin for tmux](https://github.com/catppuccin/tmux)** — loaded
  directly (not via TPM) because of a name conflict with TPM's own naming:
  ```sh
  git clone https://github.com/catppuccin/tmux.git ~/.tmux/plugins/tmux
  ```

### Optional

- **fzf** — oh-my-zsh's `fzf` plugin (already in `plugins=(...)`) wires up
  `Ctrl-R`/`Ctrl-T`/`Alt-C` automatically if fzf is on your `PATH`, and is a
  no-op if it isn't.
  - macOS: `brew install fzf`
  - Debian/Ubuntu: `sudo apt install fzf`
- **A vim plugin manager + vim-tmux-navigator** — for seamless
  `Ctrl-h/j/k/l` pane navigation between vim splits and tmux panes (see
  [TUTORIAL.md](TUTORIAL.md#cross-tool-integration)). vim configuration
  itself is not managed by this repo.
- **Ghostty** + a Nerd Font (macOS only) — the `ghostty` package assumes the
  [Ghostty](https://ghostty.org) terminal app is installed, and its config
  sets a Nerd Font for glyph rendering (icons in tmux, etc.):
  ```sh
  brew install --cask ghostty font-jetbrains-mono-nerd-font
  ```

## Install

```sh
git clone https://github.com/shadyeip/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow -t ~ zsh tmux git
```

On macOS, also stow the terminal config:

```sh
stow -t ~ ghostty
```

Stow will refuse to overwrite a file that already exists and isn't a symlink
into this repo (e.g. a pre-existing `~/.zshrc`). Back up or remove any
conflicting file yourself before stowing — nothing does that for you
automatically. To re-stow after a conflict is resolved, or after pulling new
files, use `stow -R -t ~ <package>`.

### Git identity

`git/.config/git/config` includes `~/.config/git/config.local`, which isn't
part of this repo (it's per-machine and untracked). Create it yourself:

```sh
mkdir -p ~/.config/git
cat > ~/.config/git/config.local <<'EOF'
[user]
    name = Your Name
    email = you@example.com
EOF
```

## Update

Pull the latest changes and reload your shell:

```sh
dotup
```

This is a zsh function (`~/.config/zsh/05-functions.zsh`, aliased to
`dotup`/`update_dotfiles`) that runs `git pull` in this repo and re-sources
`~/.zshrc`. If a new file or package was added, re-run `stow -R -t ~
<package>` yourself afterward.

## Uninstall

```sh
cd ~/dotfiles
stow -D -t ~ zsh tmux git ghostty
```

## Remote copy/paste over SSH

Yanking in tmux copy mode (`prefix + [`, select with vi keys, `y`) sends the
selection to the terminal via an **OSC 52** escape sequence — tmux itself
emits this (`set-clipboard on` in `tmux.conf`), so it works regardless of
what editor or program is running in the pane. `allow-passthrough on` lets
the escape sequence travel through tmux even when tmux itself is the thing
running inside an SSH session, so:

- SSH from your Mac into a Linux box, start/attach tmux there, yank text —
  it lands in your Mac's clipboard.
- This requires the **local** terminal (the one actually drawing pixels on
  your Mac — Ghostty, in this repo's config) to support OSC 52. It does not
  depend on any tool running on the remote box beyond tmux.

## Zsh Load Order

`~/.zshrc` sets up oh-my-zsh, then sources everything in
`zsh/.config/zsh/` in alphabetical order via number prefixes, before finally
sourcing `oh-my-zsh.sh` itself:

1. `01-exports.zsh` — env vars, PATH
2. `02-completions.zsh` — completion styling (compinit itself runs inside
   `oh-my-zsh.sh`, sourced last)
3. `03-keybindings.zsh` — key bindings
4. `04-aliases.zsh` — aliases
5. `05-functions.zsh` — functions

## Tmux Keybindings

### Splits

- `prefix -` — horizontal split
- `prefix |` — vertical split

### Pane Sync

- `prefix s` — toggle synchronized input to all panes

### vim-tmux-navigator

- `Ctrl-h/j/k/l` — seamless navigation between vim splits and tmux panes
  (requires the matching plugin in your vim config — see
  [Prerequisites](#prerequisites))

### tmux-yank

- Enter copy mode: `prefix + [`
- Select text (vi keys), then `y` to yank to clipboard

### tmux-resurrect

- `prefix + Ctrl-s` — save session
- `prefix + Ctrl-r` — restore session

### extrakto

- `prefix + tab` — fuzzy-find text from scrollback

## Zsh Plugins

Configured via `plugins=(...)` in `zsh/.zshrc`, loaded by oh-my-zsh. See
[Prerequisites](#prerequisites) for how to install the ones oh-my-zsh
doesn't bundle.

- **git** — oh-my-zsh's bundled git aliases/helpers
- **fzf** — `Ctrl-R` history, `Ctrl-T` file path, `Alt-C` cd (no-op if fzf
  isn't installed)
- **zsh-autosuggestions** — fish-like inline suggestions (right arrow to
  accept)
- **zsh-syntax-highlighting** — colorizes commands as you type

For a detailed walkthrough of keybindings and vim motions, see
[TUTORIAL.md](TUTORIAL.md).
