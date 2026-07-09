# dotfiles

Personal dotfiles built on off-the-shelf tools instead of hand-rolled config:
[Oh My Zsh](https://ohmyz.sh) for the shell, [lazy.nvim](https://github.com/folke/lazy.nvim)
for Neovim, [TPM](https://github.com/tmux-plugins/tpm) for tmux, all linked into
place with [GNU Stow](https://www.gnu.org/software/stow/).

Designed around one workflow: a **macOS host** where the terminal runs, and a
**Linux box reached over SSH** where most dev work happens, tied together with
**tmux**. The Mac side needs **no Homebrew and almost nothing installed** — all
the heavy tooling lives on the Linux box.

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
├── apt-packages.txt           # Debian/Ubuntu packages (Linux dev box)
└── install.sh                 # one installer for both machines
```

Each top-level directory is a stow package linked into `$HOME`. There's no
Brewfile: the Mac installs no packages (see below).

## Install

```sh
git clone https://github.com/shadyeip/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Run it as your normal user (not with `sudo`) on **both** your Mac and the Linux
box — it detects the OS and does the right thing. The script:

1. Installs packages — **only on Linux** (`apt`, asks first), where it also
   fetches the official Neovim release since the config needs Neovim ≥ 0.11 and
   the apt package is too old. **On macOS it installs nothing** (no package
   manager, no Homebrew).
2. Installs Oh My Zsh and the two external zsh plugins (just `git` clones).
3. Backs up anything conflicting to `~/.dotfiles_backup/`, then stows the configs
   (falls back to plain symlinks if `stow` isn't installed).
4. Sets your login shell to zsh (asks first).
5. Prompts for your git identity if it isn't set.
6. Installs TPM (only if tmux is present).

Neovim installs its own plugins, LSP servers, and Treesitter parsers the first
time you open it. In tmux, press `prefix + I` once to install the tmux plugins.

### Options

| Flag | Effect |
|------|--------|
| `--yes` / `-y` | Answer "yes" to every prompt (unattended). |
| `--no-packages` | Skip the `apt` step too (Linux). macOS already installs nothing. |
| `--verify` | Check symlinks and dependencies, then exit without changing anything. |

### What the Mac actually needs

Nothing from a package manager. Everything the shell setup depends on either
ships with macOS or is fetched by a plain `git` clone:

| Need | How it's satisfied |
|------|--------------------|
| **zsh** | Preinstalled on macOS. |
| **git** | Comes with the Xcode Command Line Tools (`xcode-select --install`). |
| **Oh My Zsh** + plugins | Cloned by `install.sh`. |
| **Nerd Font glyphs** | Bundled in Ghostty — no font install. |
| **Ghostty** | Download the app from [ghostty.org](https://ghostty.org) (a normal `.app`, no brew). |

That's the whole list. Anything else — `tmux`, `fzf`, `neovim` for *local* use —
is optional; grab it however your machine allows and it lights up on the next
shell. The real dev toolchain (neovim, LSP servers, go, node, ripgrep, …) lives
on the Linux box, installed there by `apt`.

## The macOS → SSH → Linux workflow

The same repo drives both machines:

- **On the Mac** (where Ghostty runs): stows the shell + Ghostty config and
  installs Oh My Zsh — no packages. Ghostty's bundled Nerd Font makes the
  `agnoster` prompt, tmux, and Neovim icons render with nothing extra installed.
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
