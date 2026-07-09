# dotfiles

Personal dotfiles built on off-the-shelf tools instead of hand-rolled config:
[Oh My Zsh](https://ohmyz.sh) for the shell, [lazy.nvim](https://github.com/folke/lazy.nvim)
for Neovim, [TPM](https://github.com/tmux-plugins/tpm) for tmux, all linked into
place with [GNU Stow](https://www.gnu.org/software/stow/).

Designed around one workflow: a **macOS host** where the terminal runs, and a
**Linux box reached over SSH** where most dev work happens, tied together with
**tmux**.

## What's included

- **zsh** — Oh My Zsh with the `agnoster` theme and the `git`, `tmux`, `fzf`,
  `docker`, `kubectl`, `golang`, `terraform`, `gcloud`, and `python` plugins,
  plus `zsh-autosuggestions` and `zsh-syntax-highlighting`.
- **tmux** — Catppuccin Mocha, vim-tmux-navigator, tmux-yank, resurrect, and
  extrakto via TPM.
- **nvim** — lazy.nvim with Catppuccin, Treesitter, Telescope, LSP (Mason), and
  format-on-save.
- **git** — global config with a few aliases; identity kept in an untracked
  `config.local`.
- **ghostty** — terminal config (macOS only; skipped on Linux).

## Structure

```
dotfiles/
├── zsh/.zshrc                 # → ~/.zshrc  (Oh My Zsh config)
├── git/.config/git/           # → ~/.config/git/
├── tmux/.config/tmux/         # → ~/.config/tmux/
├── nvim/.config/nvim/         # → ~/.config/nvim/
├── ghostty/.config/ghostty/   # → ~/.config/ghostty/  (macOS only)
├── Brewfile                   # macOS packages
├── apt-packages.txt           # Debian/Ubuntu packages
└── install.sh                 # one installer for both machines
```

Each top-level directory is a stow package linked into `$HOME`.

## Install

```sh
git clone https://github.com/shadyeip/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Run it as your normal user (not with `sudo`) on **both** your Mac and the Linux
box — it detects the OS and does the right thing. The script:

1. Installs packages — `brew bundle` on macOS, `apt` on Debian/Ubuntu (asks
   first). On Linux it fetches the official Neovim release, since the nvim
   config needs Neovim ≥ 0.11 and the apt package is too old.
2. Installs Oh My Zsh and the two external zsh plugins.
3. Backs up anything conflicting to `~/.dotfiles_backup/`, then stows the configs.
4. Sets your login shell to zsh (asks first).
5. Prompts for your git identity if it isn't set.
6. Installs TPM.

Neovim installs its own plugins, LSP servers, and Treesitter parsers the first
time you open it. In tmux, press `prefix + I` once to install the tmux plugins.

### Options

| Flag | Effect |
|------|--------|
| `--yes` / `-y` | Answer "yes" to every prompt (unattended). |
| `--no-packages` | Skip the package manager entirely — just Oh My Zsh + config links. For a locked-down Mac with no Homebrew; falls back to plain symlinks if `stow` is missing. |
| `--verify` | Check symlinks and dependencies, then exit without changing anything. |

### macOS without Homebrew

```sh
./install.sh --no-packages
```

Links the configs and installs Oh My Zsh (needs `git`, which ships with the
Xcode Command Line Tools) without touching a package manager. Install the actual
tools — neovim, tmux, fzf, ripgrep, node, go — however your machine allows, and
they light up on the next shell.

## The macOS → SSH → Linux workflow

The same repo drives both machines:

- **On the Mac** (where Ghostty runs): stows everything including the Ghostty
  terminal config and the Nerd Font (needed so the `agnoster` prompt, tmux, and
  Neovim icons render).
- **On the Linux VM** (over SSH): stows the shell/editor configs, skips Ghostty.
  Neovim, its LSP servers, and Treesitter parsers all live on the VM — right
  next to your code, so completion and diagnostics have no round-trip latency.

Two things make the remote experience match local:

- **Prompt context** — `agnoster` hides `user@host` locally but shows it inside
  an SSH session, so you always know whether you're on the Mac or the VM.
- **Clipboard** — the VM has no `pbcopy`, so Neovim routes yanks through OSC 52
  escapes; tmux (`set-clipboard on` + `allow-passthrough on`) and Ghostty pass
  them through to the Mac's clipboard.

## Customizing

- **Different prompt?** Set `ZSH_THEME="robbyrussell"` (or anything else) in an
  untracked `~/.zshrc.local` — it's sourced at the end of `.zshrc`.
- **Machine-specific shell tweaks?** Put them in `~/.zshrc.local`.
- **Machine-specific tmux tweaks?** Put them in `~/.config/tmux/local.conf`
  (sourced by `tmux.conf`, gitignored).

## Update

Pull the latest and repair any links:

```sh
cd ~/dotfiles && git pull && ./install.sh --verify
```

## Tmux keybindings

| Key | Action |
|-----|--------|
| `prefix -` / `prefix \|` | Split horizontal / vertical |
| `prefix h/j/k/l` | Select pane (vim-style) |
| `Ctrl-h/j/k/l` | Move between vim splits and tmux panes (vim-tmux-navigator) |
| `prefix s` | Toggle synchronized input to all panes |
| `prefix + [` then `v`/`y` | Copy mode: select / yank to clipboard |
| `prefix + Ctrl-s` / `Ctrl-r` | Save / restore session (resurrect) |
| `prefix + Tab` | Fuzzy-grab text from scrollback (extrakto) |

## Neovim

Leader key: `Space`. `Space f` find files, `Space g` live grep, `Space b`
buffers, `gd` go to definition, `gr` references, `K` hover, `Space r` rename,
`Space F` format. LSP servers (pyright, gopls, lua_ls, ts_ls, terraformls) and
formatters (black, prettier, stylua, gofmt, terraform_fmt) auto-install via
Mason.

For a vim-motions walkthrough and the full keybinding reference, see
[TUTORIAL.md](TUTORIAL.md).
