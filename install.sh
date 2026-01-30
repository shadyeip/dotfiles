#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

info()  { echo "[info]  $*"; }
warn()  { echo "[warn]  $*"; }
err()   { echo "[error] $*" >&2; }

backup_and_link() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            info "Already linked: $dst -> $src"
            return
        fi
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/"
        warn "Backed up existing $dst to $BACKUP_DIR/"
    fi
    ln -s "$src" "$dst"
    info "Linked: $dst -> $src"
}

# Detect OS
case "$OSTYPE" in
    darwin*)  OS="macOS" ;;
    linux*)   OS="Linux" ;;
    *)        OS="Unknown"; warn "Unrecognized OS: $OSTYPE" ;;
esac
info "Detected OS: $OS"
info "Detected shell: $SHELL"

# Symlink .zsh directory
backup_and_link "$DOTFILES_DIR/.zsh" "$HOME/.zsh"

# Symlink .tmux.conf
backup_and_link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Append zsh loader to ~/.zshrc if not present
LOADER_MARKER="# Load dotfiles"
if [ -f "$HOME/.zshrc" ] && grep -qF "$LOADER_MARKER" "$HOME/.zshrc"; then
    info "Loader block already present in ~/.zshrc"
else
    cat >> "$HOME/.zshrc" <<'EOF'

# Load dotfiles
# export CUSTOM_HOSTNAME=""
# export CUSTOM_USERNAME=""
# export IS_SAFE_MACHINE=true

for file in ~/.zsh/*.zsh; do
    source "$file"
done
EOF
    info "Appended loader block to ~/.zshrc"
fi

echo ""
echo "=== Install Summary ==="
echo "  OS:         $OS"
echo "  ~/.zsh      -> $DOTFILES_DIR/.zsh"
echo "  ~/.tmux.conf -> $DOTFILES_DIR/.tmux.conf"
echo "  ~/.zshrc     loader block present"
if [ -d "$BACKUP_DIR" ]; then
    echo "  Backups in:  $BACKUP_DIR"
fi
echo ""
echo "Restart your shell or run: source ~/.zshrc"
