#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# --verify mode: check symlinks and dependencies, then exit
if [[ "${1:-}" == "--verify" ]]; then
    echo "Verifying dotfiles installation..."
    errors=0

    # Check dependencies
    for cmd in starship nvim gcc fzf rg git tmux; do
        if command -v "$cmd" &>/dev/null; then
            echo "  [ok] $cmd"
        else
            echo "  [MISSING] $cmd"
            errors=$((errors + 1))
        fi
    done

    # Check symlinks
    check_link() {
        local dst="$1"
        local src="$2"
        if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
            echo "  [ok] $dst -> $src"
        elif [[ -L "$dst" ]]; then
            echo "  [WRONG] $dst -> $(readlink "$dst") (expected $src)"
            errors=$((errors + 1))
        else
            echo "  [MISSING] $dst"
            errors=$((errors + 1))
        fi
    }
    check_link "$HOME/.zsh"                    "$DOTFILES/.zsh"
    check_link "$HOME/.tmux.conf"              "$DOTFILES/tmux/tmux.conf"
    check_link "$HOME/.config/starship.toml"   "$DOTFILES/starship/starship.toml"
    check_link "$HOME/.gitconfig"              "$DOTFILES/git/gitconfig"
    check_link "$HOME/.gitignore_global"       "$DOTFILES/git/gitignore_global"
    check_link "$HOME/.config/ghostty/config"  "$DOTFILES/ghostty/config"
    check_link "$HOME/.config/nvim"            "$DOTFILES/nvim"

    # Check zshrc loader block
    if grep -qF "# >>> dotfiles >>>" "$HOME/.zshrc" 2>/dev/null; then
        echo "  [ok] zshrc loader block"
    else
        echo "  [MISSING] zshrc loader block"
        errors=$((errors + 1))
    fi

    # Check TPM
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        echo "  [ok] TPM"
    else
        echo "  [MISSING] TPM"
        errors=$((errors + 1))
    fi

    # Check Treesitter parsers
    PARSER_DIR="$HOME/.local/share/nvim/site/parser"
    missing_parsers=()
    for lang in bash c css dockerfile go html javascript json lua markdown markdown_inline python rust terraform toml typescript yaml; do
        if [[ ! -f "$PARSER_DIR/$lang.so" ]]; then
            missing_parsers+=("$lang")
        fi
    done
    if [[ ${#missing_parsers[@]} -eq 0 ]]; then
        echo "  [ok] Treesitter parsers"
    else
        echo "  [MISSING] Treesitter parsers: ${missing_parsers[*]}"
        errors=$((errors + 1))
    fi

    echo ""
    if [[ $errors -eq 0 ]]; then
        echo "All checks passed."
    else
        echo "$errors issue(s) found. Run ./install.sh to fix."
    fi
    exit $errors
fi

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

# Install gcc (needed for Treesitter parser compilation)
if ! command -v gcc &>/dev/null; then
    echo "Installing gcc..."
    if [[ "$OS" == "macos" ]]; then
        brew install gcc
    else
        sudo apt install -y build-essential
    fi
else
    echo "gcc already installed"
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

# Install ripgrep if not present (needed for Telescope live grep)
if ! command -v rg &>/dev/null; then
    echo "Installing ripgrep..."
    if [[ "$OS" == "macos" ]]; then
        brew install ripgrep
    else
        sudo apt install -y ripgrep
    fi
else
    echo "ripgrep already installed"
fi

# Backup and symlink helper (skips if already correct)
link_file() {
    local src="$1"
    local dst="$2"

    # Skip if symlink already points to the right place
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "Already linked $dst"
        return
    fi

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
link_file "$DOTFILES/.zsh"                 "$HOME/.zsh"
link_file "$DOTFILES/tmux/tmux.conf"       "$HOME/.tmux.conf"
link_file "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES/git/gitconfig"        "$HOME/.gitconfig"
link_file "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"
link_file "$DOTFILES/ghostty/config"      "$HOME/.config/ghostty/config"
link_file "$DOTFILES/nvim"                "$HOME/.config/nvim"

# Zshrc loader block
ZSHRC="$HOME/.zshrc"
MARKER="# >>> dotfiles >>>"
if ! grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    cat >> "$ZSHRC" <<'EOF'
# >>> dotfiles >>>
for f in ~/.zsh/*.zsh; do source "$f"; done
eval "$(starship init zsh)"
# <<< dotfiles <<<
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

# Install Treesitter parsers
# The nvim-treesitter install() is async and unreliable in headless mode,
# so we compile parsers directly from cached sources.
PARSER_DIR="$HOME/.local/share/nvim/site/parser"
mkdir -p "$PARSER_DIR"

TS_LANGS=(bash c css dockerfile go html javascript json lua markdown python rust terraform toml typescript yaml)

echo "Installing Treesitter parsers..."

# Check if all parsers are already compiled
all_compiled=true
for lang in "${TS_LANGS[@]}"; do
    [[ ! -f "$PARSER_DIR/$lang.so" ]] && all_compiled=false && break
done
[[ ! -f "$PARSER_DIR/markdown_inline.so" ]] && all_compiled=false

if [[ "$all_compiled" == true ]]; then
    echo "  All parsers already compiled, skipping download"
else
    # Trigger downloads by running nvim briefly
    nvim --headless -c "lua require('nvim-treesitter').install({$(printf "'%s'," "${TS_LANGS[@]}")})" -c "sleep 15" -c "qa" 2>&1 | cat
fi

# Compile each parser from cached sources
TS_CACHE="$HOME/.cache/nvim"
compile_parser() {
    local lang="$1"
    local src_dir="$2"
    local out="$PARSER_DIR/$lang.so"
    if [[ -f "$out" ]]; then
        echo "  $lang: already compiled"
        return
    fi
    if [[ ! -f "$src_dir/parser.c" ]]; then
        echo "  $lang: source not found, skipping"
        return
    fi
    echo "  $lang: compiling..."
    local srcs=("$src_dir/parser.c")
    [[ -f "$src_dir/scanner.c" ]] && srcs+=("$src_dir/scanner.c")
    cc -shared -o "$out" -I "$src_dir" "${srcs[@]}" -O2 2>&1 || echo "  $lang: compilation failed"
}

for lang in "${TS_LANGS[@]}"; do
    src_dir="$TS_CACHE/tree-sitter-$lang/src"
    # Some parsers have nested source layouts
    if [[ ! -d "$src_dir" ]]; then
        src_dir="$TS_CACHE/tree-sitter-$lang/$lang/src"
    fi
    if [[ ! -d "$src_dir" ]]; then
        src_dir="$TS_CACHE/tree-sitter-$lang/tree-sitter-$lang/src"
    fi
    compile_parser "$lang" "$src_dir"
done

# Markdown inline is a sub-parser bundled with markdown
compile_parser "markdown_inline" "$TS_CACHE/tree-sitter-markdown/tree-sitter-markdown-inline/src"

echo "Treesitter parsers installed"

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
