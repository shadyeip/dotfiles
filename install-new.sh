#!/usr/bin/env bash
set -euo pipefail

# Detect real user when running with sudo
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    echo "Running as sudo, installing for user: $REAL_USER ($REAL_HOME)"
    # Helper to run commands as the real user
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

# --verify mode: check symlinks and dependencies, then exit
if [[ "${1:-}" == "--verify" ]]; then
    echo "Verifying dotfiles installation..."
    errors=0

    # Check dependencies
    for cmd in zsh starship nvim gcc fzf rg git tmux node go; do
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
    check_link "$REAL_HOME/.zsh"                    "$DOTFILES/.zsh"
    check_link "$REAL_HOME/.tmux.conf"              "$DOTFILES/tmux/tmux.conf"
    check_link "$REAL_HOME/.config/starship.toml"   "$DOTFILES/starship/starship.toml"
    check_link "$REAL_HOME/.gitconfig"              "$DOTFILES/git/gitconfig"
    check_link "$REAL_HOME/.gitignore_global"       "$DOTFILES/git/gitignore_global"
    check_link "$REAL_HOME/.config/ghostty/config"  "$DOTFILES/ghostty/config"
    check_link "$REAL_HOME/.config/nvim"            "$DOTFILES/nvim"

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

    # Check tmux-local.conf and AI CLIs
    if [[ -f "$REAL_HOME/.tmux-local.conf" ]]; then
        echo "  [ok] tmux-local.conf"
        # Check AI CLIs based on what's configured
        if grep -q "claude" "$REAL_HOME/.tmux-local.conf"; then
            if command -v claude &>/dev/null; then
                echo "  [ok] claude CLI"
            else
                echo "  [MISSING] claude CLI"
                errors=$((errors + 1))
            fi
        fi
        if grep -q "gemini" "$REAL_HOME/.tmux-local.conf"; then
            if command -v gemini &>/dev/null; then
                echo "  [ok] gemini CLI"
            else
                echo "  [MISSING] gemini CLI"
                errors=$((errors + 1))
            fi
        fi
    else
        echo "  [MISSING] tmux-local.conf (run install.sh to configure AI assistant)"
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
        run_as_user mkdir -p "$BACKUP_DIR"
        echo "Backing up $dst -> $BACKUP_DIR/"
        run_as_user mv "$dst" "$BACKUP_DIR/"
    fi

    run_as_user mkdir -p "$(dirname "$dst")"
    run_as_user ln -sf "$src" "$dst"
    echo "Linked $src -> $dst"
}

# Symlinks
link_file "$DOTFILES/.zsh"                 "$REAL_HOME/.zsh"
link_file "$DOTFILES/tmux/tmux.conf"       "$REAL_HOME/.tmux.conf"
link_file "$DOTFILES/starship/starship.toml" "$REAL_HOME/.config/starship.toml"
link_file "$DOTFILES/git/gitconfig"        "$REAL_HOME/.gitconfig"
link_file "$DOTFILES/git/gitignore_global" "$REAL_HOME/.gitignore_global"
link_file "$DOTFILES/ghostty/config"      "$REAL_HOME/.config/ghostty/config"
link_file "$DOTFILES/nvim"                "$REAL_HOME/.config/nvim"

# Generate tmux-local.conf with AI keybindings
TMUX_LOCAL="$REAL_HOME/.tmux-local.conf"
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
} | run_as_user tee "$TMUX_LOCAL" > /dev/null
echo "Generated $TMUX_LOCAL"

# Zshrc loader block
ZSHRC="$REAL_HOME/.zshrc"
MARKER="# >>> dotfiles >>>"
if ! grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    run_as_user tee -a "$ZSHRC" > /dev/null <<'EOF'

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
TPM_DIR="$REAL_HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    echo "Installing TPM..."
    run_as_user git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "TPM already installed"
fi

# Install Treesitter parsers
# The nvim-treesitter install() is async and unreliable in headless mode,
# so we compile parsers directly from cached sources.
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
if [[ ! -d "$REAL_HOME/.tmux/plugins/catppuccin" ]]; then
    NOTES+=("  - In tmux, press prefix + I to install plugins")
fi
if [[ ! -f "$REAL_HOME/.gitconfig.local" ]]; then
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
