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
- [x] Add a `--verify` flag to `install.sh` to check symlinks and dependencies
- [x] Add idempotency checks so it skips already-correct symlinks

## Organization
- [x] Move gcloud aliases from `aliases.zsh` into a separate `.zsh/gcloud.zsh`
- [x] Resolve prompt conflict — remove either custom `prompt.zsh` or Starship (pick one)

## Zsh Startup Performance
- [x] Lazy-load nvm (defer sourcing nvm.sh until `nvm`/`node`/`npm`/`npx` is first called)
- [x] Lazy-load virtualenvwrapper (defer hook until `workon`/`mkvirtualenv` is first called)
- [x] Fix compdump rebuild on every startup (removed duplicate compinit in completions.zsh)
- [x] Deduplicate PATH entries (removed duplicate homebrew in exports.zsh, duplicate dotfiles block, ruby eval)

## Nice-to-haves
- [x] Expand Starship config with language modules (python, node, go, rust, etc.)
- [x] Add a Brewfile for declarative CLI tool installation on new Macs
