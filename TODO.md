# Dotfiles Improvement Plan

## Cleanup
- [x] Remove duplicate `zsh/` directory (keep `.zsh/`) and legacy root `.tmux.conf` (keep `tmux/tmux.conf`)
- [x] Fix hardcoded `~/dev/dotfiles2` path in README

## Zsh Plugins
- [x] Populate `plugins.zsh` with zsh-autosuggestions, zsh-syntax-highlighting, and fzf keybindings/completions

## Neovim
- [x] Add Treesitter to `nvim/init.lua`
- [x] Add Telescope to `nvim/init.lua`
- [x] Add LSP config to `nvim/init.lua`
- [x] Add custom keybindings to `nvim/init.lua`

## Install Script Hardening
- [ ] Add a `--verify` flag to `install.sh` to check symlinks and dependencies
- [ ] Add idempotency checks so it skips already-correct symlinks

## Organization
- [ ] Move gcloud aliases from `aliases.zsh` into a separate `.zsh/gcloud.zsh`
- [ ] Resolve prompt conflict — remove either custom `prompt.zsh` or Starship (pick one)

## Nice-to-haves
- [ ] Expand Starship config with language modules (python, node, go, rust, etc.)
- [ ] Add a Brewfile for declarative CLI tool installation on new Macs
