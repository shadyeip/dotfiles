#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
fi
echo "Detected OS: $OS"

# Install Starship if not present
if ! command -v starship &>/dev/null; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
else
    echo "Starship already installed"
fi

# Install Neovim if not present
if ! command -v nvim &>/dev/null; then
    echo "Installing Neovim..."
    if [[ "$OS" == "macos" ]]; then
        brew install neovim
    else
        sudo apt install -y neovim
    fi
else
    echo "Neovim already installed"
fi

# Install fzf if not present
if ! command -v fzf &>/dev/null; then
    echo "Installing fzf..."
    if [[ "$OS" == "macos" ]]; then
        brew install fzf
    else
        sudo apt install -y fzf
    fi
else
    echo "fzf already installed"
fi

# Backup and symlink helper
link_file() {
    local src="$1"
    local dst="$2"

    if [[ -e "$dst" || -L "$dst" ]]; then
        mkdir -p "$BACKUP_DIR"
        echo "Backing up $dst -> $BACKUP_DIR/"
        mv "$dst" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "Linked $src -> $dst"
}

# Symlinks
link_file "$DOTFILES/zsh"                  "$HOME/.zsh"
link_file "$DOTFILES/tmux/tmux.conf"       "$HOME/.tmux.conf"
link_file "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES/git/gitconfig"        "$HOME/.gitconfig"
link_file "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"
link_file "$DOTFILES/ghostty/config"      "$HOME/.config/ghostty/config"
link_file "$DOTFILES/nvim"                "$HOME/.config/nvim"

# Zshrc loader block
ZSHRC="$HOME/.zshrc"
MARKER="# >>> dotfiles2 >>>"
if ! grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    cat >> "$ZSHRC" <<'EOF'
# >>> dotfiles2 >>>
for f in ~/.zsh/*.zsh; do source "$f"; done
eval "$(starship init zsh)"
# <<< dotfiles2 <<<
EOF
    echo "Added loader block to ~/.zshrc"
else
    echo "Loader block already in ~/.zshrc, skipping"
fi

# TPM
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "TPM already installed"
fi

echo ""
echo "Done!"

NOTES=()
if [[ ! -d "$HOME/.tmux/plugins/catppuccin" ]]; then
    NOTES+=("  - In tmux, press prefix + I to install plugins")
fi
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    NOTES+=("  - Create ~/.gitconfig.local with your name/email:"
            "      [user]"
            "        name = Your Name"
            "        email = you@example.com")
fi
if [[ ${#NOTES[@]} -gt 0 ]]; then
    echo ""
    echo "Next steps:"
    printf '%s\n' "${NOTES[@]}"
fi
