#!/usr/bin/env bash
set -euo pipefail

# Detect real user when running with sudo
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    echo "Running as sudo, installing for user: $REAL_USER ($REAL_HOME)"
    run_as_user() {
        sudo -u "$REAL_USER" "$@"
    }
else
    REAL_USER="$(whoami)"
    REAL_HOME="$HOME"
    run_as_user() {
        "$@"
    }
fi

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$REAL_HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
STOW_PACKAGES=(git tmux nvim starship ghostty zsh)

# --verify mode: check symlinks and dependencies, then exit
if [[ "${1:-}" == "--verify" ]]; then
    echo "Verifying dotfiles installation..."
    errors=0

    # Check dependencies
    for cmd in zsh stow starship nvim gcc fzf rg git tmux node go; do
        if command -v "$cmd" &>/dev/null; then
            echo "  [ok] $cmd"
        else
            echo "  [MISSING] $cmd"
            errors=$((errors + 1))
        fi
    done

    # Check stow-managed symlinks
    check_path() {
        local dst="$1"
        if [[ -e "$dst" || -L "$dst" ]]; then
            echo "  [ok] $dst"
        else
            echo "  [MISSING] $dst"
            errors=$((errors + 1))
        fi
    }
    check_path "$REAL_HOME/.config/git/config"
    check_path "$REAL_HOME/.config/git/ignore"
    check_path "$REAL_HOME/.config/tmux/tmux.conf"
    check_path "$REAL_HOME/.config/nvim/init.lua"
    check_path "$REAL_HOME/.config/starship.toml"
    check_path "$REAL_HOME/.config/ghostty/config"
    check_path "$REAL_HOME/.config/zsh/01-exports.zsh"

    # Check zshrc loader block
    if grep -qF "# >>> dotfiles >>>" "$REAL_HOME/.zshrc" 2>/dev/null; then
        echo "  [ok] zshrc loader block"
    else
        echo "  [MISSING] zshrc loader block"
        errors=$((errors + 1))
    fi

    # Check TPM
    if [[ -d "$REAL_HOME/.tmux/plugins/tpm" ]]; then
        echo "  [ok] TPM"
    else
        echo "  [MISSING] TPM"
        errors=$((errors + 1))
    fi

    # Check tmux local.conf and AI CLIs
    if [[ -f "$REAL_HOME/.config/tmux/local.conf" ]]; then
        echo "  [ok] tmux local.conf"
        if grep -q "claude" "$REAL_HOME/.config/tmux/local.conf"; then
            if command -v claude &>/dev/null; then
                echo "  [ok] claude CLI"
            else
                echo "  [MISSING] claude CLI"
                errors=$((errors + 1))
            fi
        fi
        if grep -q "gemini" "$REAL_HOME/.config/tmux/local.conf"; then
            if command -v gemini &>/dev/null; then
                echo "  [ok] gemini CLI"
            else
                echo "  [MISSING] gemini CLI"
                errors=$((errors + 1))
            fi
        fi
    else
        echo "  [MISSING] tmux local.conf (run install.sh to configure AI assistant)"
        errors=$((errors + 1))
    fi

    # Check git identity
    if [[ -f "$REAL_HOME/.config/git/config.local" ]]; then
        echo "  [ok] git identity (config.local)"
    else
        echo "  [MISSING] git identity (~/.config/git/config.local)"
        errors=$((errors + 1))
    fi

    # Check Treesitter parsers
    PARSER_DIR="$REAL_HOME/.local/share/nvim/site/parser"
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

# AI Assistant selection
echo ""
echo "Which AI assistant(s) do you want to use?"
echo "  1) Claude"
echo "  2) Gemini"
echo "  3) Both"
echo ""
read -p "Select [1-3]: " ai_choice

case "$ai_choice" in
    1) AI_ASSISTANTS=("claude") ;;
    2) AI_ASSISTANTS=("gemini") ;;
    3) AI_ASSISTANTS=("claude" "gemini") ;;
    *) echo "Invalid selection, defaulting to Claude"; AI_ASSISTANTS=("claude") ;;
esac
echo "Selected: ${AI_ASSISTANTS[*]}"

# Install Claude CLI if selected
if [[ " ${AI_ASSISTANTS[*]} " =~ " claude " ]]; then
    if ! command -v claude &>/dev/null; then
        echo "Installing Claude CLI..."
        run_as_user npm install -g @anthropic-ai/claude-code
    else
        echo "Claude CLI already installed"
    fi
fi

# Install Gemini CLI if selected
if [[ " ${AI_ASSISTANTS[*]} " =~ " gemini " ]]; then
    if ! command -v gemini &>/dev/null; then
        echo "Installing Gemini CLI..."
        run_as_user npm install -g @google/gemini-cli
    else
        echo "Gemini CLI already installed"
    fi
fi

# Install zsh if not present
if ! command -v zsh &>/dev/null; then
    echo "Installing zsh..."
    if [[ "$OS" == "macos" ]]; then
        brew install zsh
    else
        sudo apt install -y zsh
    fi
else
    echo "zsh already installed"
fi

# Install stow if not present
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    if [[ "$OS" == "macos" ]]; then
        brew install stow
    else
        sudo apt install -y stow
    fi
else
    echo "stow already installed"
fi

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

# Install Node.js if not present (needed for Mason LSP servers like pyright)
if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."
    if [[ "$OS" == "macos" ]]; then
        brew install node
    else
        sudo apt install -y nodejs npm
    fi
else
    echo "Node.js already installed"
fi

# Install Go if not present (needed for Mason LSP servers like gopls)
if ! command -v go &>/dev/null; then
    echo "Installing Go..."
    if [[ "$OS" == "macos" ]]; then
        brew install go
    else
        sudo apt install -y golang
    fi
else
    echo "Go already installed"
fi

# Migration: remove old symlinks from previous dotfiles layout
echo ""
echo "Cleaning up old symlinks..."
OLD_LINKS=(
    "$REAL_HOME/.zsh"
    "$REAL_HOME/.tmux.conf"
    "$REAL_HOME/.gitconfig"
    "$REAL_HOME/.gitignore_global"
    "$REAL_HOME/.tmux-local.conf"
)
for old in "${OLD_LINKS[@]}"; do
    if [[ -L "$old" ]]; then
        echo "  Removing old symlink: $old"
        rm "$old"
    fi
done

# Also remove old stow-managed links that may conflict
OLD_CONFIG_LINKS=(
    "$REAL_HOME/.config/nvim"
    "$REAL_HOME/.config/starship.toml"
    "$REAL_HOME/.config/ghostty/config"
)
for old in "${OLD_CONFIG_LINKS[@]}"; do
    if [[ -L "$old" ]]; then
        echo "  Removing old symlink: $old"
        rm "$old"
    fi
done

# Back up existing regular files that would conflict with stow
STOW_TARGETS=(
    "$REAL_HOME/.config/git/config"
    "$REAL_HOME/.config/git/ignore"
    "$REAL_HOME/.config/tmux/tmux.conf"
    "$REAL_HOME/.config/nvim/init.lua"
    "$REAL_HOME/.config/nvim/lazy-lock.json"
    "$REAL_HOME/.config/starship.toml"
    "$REAL_HOME/.config/ghostty/config"
)
for target in "${STOW_TARGETS[@]}"; do
    if [[ -e "$target" && ! -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        echo "  Backing up existing file: $target -> $BACKUP_DIR/"
        mv "$target" "$BACKUP_DIR/"
    fi
done
# Also handle directories (e.g. ~/.config/zsh already exists as a real dir)
for dir in "$REAL_HOME/.config/nvim" "$REAL_HOME/.config/zsh"; do
    if [[ -d "$dir" && ! -L "$dir" ]]; then
        mkdir -p "$BACKUP_DIR"
        echo "  Backing up existing directory: $dir -> $BACKUP_DIR/"
        mv "$dir" "$BACKUP_DIR/"
    fi
done

# Stow all packages
echo ""
echo "Stowing dotfiles..."
run_as_user stow -v -t "$REAL_HOME" -d "$DOTFILES" "${STOW_PACKAGES[@]}"

# Generate tmux local.conf with AI keybindings
TMUX_LOCAL="$REAL_HOME/.config/tmux/local.conf"
{
    echo "# Machine-specific tmux config (generated by install.sh)"
    echo "# AI assistant keybindings"
    for ai in "${AI_ASSISTANTS[@]}"; do
        case "$ai" in
            claude)
                echo 'bind t split-window -v -c "#{pane_current_path}" \; send-keys "clear && claude --dangerously-skip-permissions" Enter \; select-layout tiled'
                echo "Added Claude keybinding (prefix + t)" >&2
                ;;
            gemini)
                echo 'bind g split-window -v -c "#{pane_current_path}" \; send-keys "clear && gemini" Enter \; select-layout tiled'
                echo "Added Gemini keybinding (prefix + g)" >&2
                ;;
        esac
    done
} > "$TMUX_LOCAL"
echo "Generated $TMUX_LOCAL"

# Git identity prompt
GIT_LOCAL="$REAL_HOME/.config/git/config.local"
if [[ ! -f "$GIT_LOCAL" ]]; then
    echo ""
    echo "Setting up git identity..."
    read -p "Your full name (for git commits): " git_name
    read -p "Your email (matching your GitHub account): " git_email
    cat > "$GIT_LOCAL" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
    echo "Created $GIT_LOCAL"
else
    echo "Git identity already configured ($GIT_LOCAL)"
fi

# Zshrc loader block
ZSHRC="$REAL_HOME/.zshrc"
MARKER="# >>> dotfiles >>>"

# Remove any old unmarked loader that sources ~/.zsh/
if grep -qE 'for .* in ~/\.zsh/\*\.zsh' "$ZSHRC" 2>/dev/null; then
    echo "Removing old zsh loader block from ~/.zshrc..."
    sed -i.bak '/for .* in ~\/\.zsh\/\*\.zsh/,/done/d' "$ZSHRC"
    rm -f "$ZSHRC.bak"
fi

if grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    echo "Loader block already in ~/.zshrc"
else
    cat >> "$ZSHRC" <<EOF

# >>> dotfiles >>>
export DOTFILES_DIR="$DOTFILES"
for f in ~/.config/zsh/*.zsh; do source "\$f"; done
eval "\$(starship init zsh)"
# <<< dotfiles <<<
EOF
    echo "Added loader block to ~/.zshrc"
fi

# TPM
TPM_DIR="$REAL_HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    echo "Installing TPM..."
    run_as_user git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "TPM already installed"
fi

# Install Treesitter parsers
PARSER_DIR="$REAL_HOME/.local/share/nvim/site/parser"
run_as_user mkdir -p "$PARSER_DIR"

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
    run_as_user nvim --headless -c "lua require('nvim-treesitter').install({$(printf "'%s'," "${TS_LANGS[@]}")})" -c "sleep 15" -c "qa" 2>&1 | cat
fi

# Compile each parser from cached sources
TS_CACHE="$REAL_HOME/.cache/nvim"
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
    run_as_user cc -shared -o "$out" -I "$src_dir" "${srcs[@]}" -O2 2>&1 || echo "  $lang: compilation failed"
}

for lang in "${TS_LANGS[@]}"; do
    src_dir="$TS_CACHE/tree-sitter-$lang/src"
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
if [[ ! -d "$REAL_HOME/.tmux/plugins/catppuccin" ]]; then
    NOTES+=("  - In tmux, press prefix + I to install plugins")
fi
if [[ ${#NOTES[@]} -gt 0 ]]; then
    echo ""
    echo "Next steps:"
    printf '%s\n' "${NOTES[@]}"
fi
