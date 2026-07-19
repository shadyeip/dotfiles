#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
ASSUME_YES=false
VERIFY=false
CONFIGS_ONLY=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --verify         Check symlinks and dependencies, then exit (no changes made)
  --configs-only   Only link the dotfiles into ~/.config; install nothing and
                   make no system changes. Works without stow or a package
                   manager (e.g. a corporate Mac with no Homebrew).
  -y, --yes        Assume "yes" to all confirmation prompts (non-interactive)
  -h, --help       Show this help and exit

By default this script installs developer tooling (zsh, stow, starship, neovim,
fzf, ripgrep, gcc, Node.js/npm, Go) and links the dotfiles into ~/.config.
It does NOT install any AI assistant tooling.

Privileged or system-wide actions (package installs, editing /etc/shells,
changing your login shell, running a downloaded installer) always ask for
confirmation first unless --yes is given. Answering "no" skips that step.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --verify) VERIFY=true ;;
        --configs-only|--stow-only) CONFIGS_ONLY=true ;;
        -y|--yes) ASSUME_YES=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Confirmation helper — defaults to "no" when non-interactive and no --yes,
# so nothing privileged happens without an explicit opt-in.
# ---------------------------------------------------------------------------
confirm() {
    if [[ "$ASSUME_YES" == true ]]; then
        return 0
    fi
    local reply
    if ! read -r -p "$1 [y/N]: " reply; then
        echo   # newline after EOF
        return 1
    fi
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

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

# Detect OS (needed to decide which packages/configs are relevant)
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
fi

# Ghostty is a GUI terminal emulator: it belongs on the desktop machine (the
# macOS host), not on a headless Linux box you SSH into. Its config is only
# stowed on macOS. Shell/editor configs (zsh, tmux, nvim, starship, git) are
# stowed on every machine.
STOW_PACKAGES=(git tmux nvim starship zsh)
if [[ "$OS" == "macos" ]]; then
    STOW_PACKAGES+=(ghostty)
fi

if [[ "$CONFIGS_ONLY" == true ]]; then
    echo "Configs-only mode: linking dotfiles; installing nothing and making no system changes."
fi

# --verify mode: check symlinks and dependencies, then exit
if [[ "$VERIFY" == true ]]; then
    echo "Verifying dotfiles installation..."
    errors=0

    # Check dependencies
    for cmd in zsh stow starship nvim gcc fzf rg git tmux node npm go; do
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
    if [[ "$OS" == "macos" ]]; then
        check_path "$REAL_HOME/.config/ghostty/config"
    fi
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

    # Check tmux local.conf
    if [[ -f "$REAL_HOME/.config/tmux/local.conf" ]]; then
        echo "  [ok] tmux local.conf"
    else
        echo "  [MISSING] tmux local.conf (run install.sh to generate it)"
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

echo "Detected OS: $OS"

# ---------------------------------------------------------------------------
# Package installation — asks once for consent to install missing packages,
# then reuses that answer for the rest of the run.
# ---------------------------------------------------------------------------
PKG_CONSENT=""   # "", "yes", or "no"

ensure_pkg_consent() {
    case "$PKG_CONSENT" in
        yes) return 0 ;;
        no)  return 1 ;;
    esac
    local via
    if [[ "$OS" == "macos" ]]; then via="brew"; else via="sudo apt"; fi
    if confirm "Install missing packages using '$via'?"; then
        PKG_CONSENT="yes"
        return 0
    else
        PKG_CONSENT="no"
        echo "Skipping package installation. Missing tools will need manual install."
        return 1
    fi
}

# pkg_install <label> <brew_formula> [apt_pkg...]
pkg_install() {
    local label="$1" brew_pkg="$2"
    shift 2
    if ! ensure_pkg_consent; then
        echo "  Skipped $label"
        return 0
    fi
    if [[ "$OS" == "macos" ]]; then
        brew install "$brew_pkg"
    else
        sudo apt install -y "$@"
    fi
}

# ===========================================================================
# Package installation and login-shell change — skipped entirely in
# --configs-only mode (no installs, no sudo, no system changes).
# ===========================================================================
if [[ "$CONFIGS_ONLY" == false ]]; then

# Install Node.js if not present (needed for npm + Mason LSP servers like pyright)
if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."
    pkg_install "Node.js" node nodejs npm
else
    echo "Node.js already installed"
fi

# Install npm if not present (needed for Mason LSP servers)
if ! command -v npm &>/dev/null; then
    echo "Installing npm..."
    pkg_install "npm" npm npm
else
    echo "npm already installed"
fi

# Install zsh if not present
if ! command -v zsh &>/dev/null; then
    echo "Installing zsh..."
    pkg_install "zsh" zsh zsh
else
    echo "zsh already installed"
fi

# Install stow if not present
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    pkg_install "stow" stow stow
else
    echo "stow already installed"
fi

# Install Starship if not present
if ! command -v starship &>/dev/null; then
    echo "Installing Starship..."
    if [[ "$OS" == "macos" ]]; then
        pkg_install "Starship" starship
    else
        # No Starship package in the default apt repos, so use the official
        # installer — but download it first so it can be inspected, and only
        # run it after confirmation, instead of piping curl straight to sh.
        if ensure_pkg_consent; then
            starship_installer="$(mktemp)"
            echo "Downloading Starship installer to $starship_installer ..."
            curl -fsSL https://starship.rs/install.sh -o "$starship_installer"
            echo "  Downloaded ($(wc -l < "$starship_installer") lines). Inspect with: less $starship_installer"
            if confirm "Run the downloaded Starship installer?"; then
                sh "$starship_installer" -- --yes
            else
                echo "  Skipped Starship. Install manually later: https://starship.rs"
            fi
            rm -f "$starship_installer"
        else
            echo "  Skipped Starship"
        fi
    fi
else
    echo "Starship already installed"
fi

# Install Neovim if not present (or too old on Linux).
# The nvim config uses the vim.lsp.config API introduced in Neovim 0.11, but the
# Debian apt package is far older, so on Linux we install the official release.
NVIM_MIN_MINOR=11

nvim_is_recent() {
    command -v nvim &>/dev/null || return 1
    local v major minor
    v="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    [[ -z "$v" ]] && return 1
    major="${v%%.*}"
    minor="${v#*.}"
    (( major > 0 || minor >= NVIM_MIN_MINOR ))
}

install_neovim_linux() {
    ensure_pkg_consent || { echo "  Skipped Neovim"; return 0; }
    local arch tarch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)  tarch="x86_64" ;;
        aarch64|arm64) tarch="arm64" ;;
        *)
            echo "  Unsupported arch '$arch'; falling back to apt neovim (may be too old)"
            sudo apt install -y neovim
            return 0
            ;;
    esac
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${tarch}.tar.gz"
    local tmp
    tmp="$(mktemp -d)"
    echo "  Downloading official Neovim release (${tarch})..."
    if ! curl -fsSL "$url" -o "$tmp/nvim.tar.gz"; then
        echo "  Download failed; falling back to apt neovim (may be too old)"
        sudo apt install -y neovim
        rm -rf "$tmp"
        return 0
    fi
    sudo rm -rf "/opt/nvim-linux-${tarch}"
    sudo tar -C /opt -xzf "$tmp/nvim.tar.gz"
    sudo ln -sf "/opt/nvim-linux-${tarch}/bin/nvim" /usr/local/bin/nvim
    rm -rf "$tmp"
    echo "  Neovim installed to /opt/nvim-linux-${tarch} (symlinked at /usr/local/bin/nvim)"
}

if nvim_is_recent; then
    echo "Neovim already installed ($(nvim --version | head -1))"
else
    echo "Installing Neovim..."
    if [[ "$OS" == "macos" ]]; then
        pkg_install "Neovim" neovim neovim
    else
        install_neovim_linux
    fi
fi

# Install gcc (needed for Treesitter parser compilation)
if ! command -v gcc &>/dev/null; then
    echo "Installing gcc..."
    pkg_install "gcc" gcc build-essential
else
    echo "gcc already installed"
fi

# Install fzf if not present
if ! command -v fzf &>/dev/null; then
    echo "Installing fzf..."
    pkg_install "fzf" fzf fzf
else
    echo "fzf already installed"
fi

# Install ripgrep if not present (needed for Telescope live grep)
if ! command -v rg &>/dev/null; then
    echo "Installing ripgrep..."
    pkg_install "ripgrep" ripgrep ripgrep
else
    echo "ripgrep already installed"
fi

# Install Go if not present (needed for Mason LSP servers like gopls)
if ! command -v go &>/dev/null; then
    echo "Installing Go..."
    pkg_install "Go" go golang
else
    echo "Go already installed"
fi

# Set default login shell to zsh for target user
ZSH_PATH="$(command -v zsh || true)"
CURRENT_LOGIN_SHELL=""

if command -v getent &>/dev/null; then
    CURRENT_LOGIN_SHELL="$(getent passwd "$REAL_USER" | cut -d: -f7 || true)"
elif [[ "$OS" == "macos" ]] && command -v dscl &>/dev/null; then
    CURRENT_LOGIN_SHELL="$(dscl . -read "/Users/$REAL_USER" UserShell 2>/dev/null | awk '{print $2}' || true)"
fi

if [[ -z "$ZSH_PATH" ]]; then
    echo "zsh not found on PATH; skipping default-shell change."
elif [[ "$CURRENT_LOGIN_SHELL" == "$ZSH_PATH" ]]; then
    echo "Default shell already set to zsh for $REAL_USER"
elif confirm "Set default login shell to zsh ($ZSH_PATH) for $REAL_USER?"; then
    echo "Setting default shell to zsh for $REAL_USER..."

    if [[ "$OS" == "linux" ]] && ! grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null; then
        echo "Adding $ZSH_PATH to /etc/shells"
        if [[ -n "${SUDO_USER:-}" ]]; then
            echo "$ZSH_PATH" >> /etc/shells
        else
            echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi
    fi

    if [[ -n "${SUDO_USER:-}" ]]; then
        if chsh -s "$ZSH_PATH" "$REAL_USER"; then
            echo "Default shell updated to zsh for $REAL_USER"
        else
            echo "Warning: could not set default shell automatically. Run: sudo chsh -s \"$ZSH_PATH\" \"$REAL_USER\""
        fi
    else
        if chsh -s "$ZSH_PATH"; then
            echo "Default shell updated to zsh"
        else
            echo "Warning: could not set default shell automatically. Run: chsh -s \"$ZSH_PATH\""
        fi
    fi
else
    echo "Skipped changing default shell. To do it later: chsh -s \"$ZSH_PATH\""
fi

fi   # end: package installation / login-shell change (skipped in --configs-only)

# ---------------------------------------------------------------------------
# Backup helpers — nothing with real content is ever removed without first
# being copied into $BACKUP_DIR, and every removed symlink is logged there.
# ---------------------------------------------------------------------------
record_removed_symlink() {
    local link="$1"
    mkdir -p "$BACKUP_DIR"
    printf '%s -> %s\n' "$link" "$(readlink "$link")" >> "$BACKUP_DIR/removed-symlinks.log"
}

backup_path() {
    local target="$1"
    mkdir -p "$BACKUP_DIR"
    echo "  Backing up: $target -> $BACKUP_DIR/"
    mv "$target" "$BACKUP_DIR/"
}

# Stow-free fallback: mirror each package's file tree into $REAL_HOME with
# symlinks, exactly as `stow` would. Used when stow isn't installed (e.g. a
# corporate Mac without Homebrew).
link_packages_manual() {
    echo "stow not found — linking configs manually (no stow required)."
    local pkg base file rel dst
    for pkg in "${STOW_PACKAGES[@]}"; do
        base="$DOTFILES/$pkg"
        [[ -d "$base" ]] || continue
        while IFS= read -r -d '' file; do
            rel="${file#"$base"/}"
            dst="$REAL_HOME/$rel"
            if [[ -e "$dst" && ! -L "$dst" ]]; then
                backup_path "$dst"
            fi
            run_as_user mkdir -p "$(dirname "$dst")"
            run_as_user ln -sfn "$file" "$dst"
            echo "  linked $dst"
        done < <(find "$base" -type f -print0)
    done
}

# Link packages using GNU Stow when available, otherwise the manual fallback.
link_packages() {
    if command -v stow &>/dev/null; then
        echo "Stowing dotfiles..."
        if ! run_as_user stow -v -t "$REAL_HOME" -d "$DOTFILES" "${STOW_PACKAGES[@]}"; then
            echo "Error: stow failed. Existing files may be in the way; check the output above." >&2
            [[ -d "$BACKUP_DIR" ]] && echo "Anything already backed up is in $BACKUP_DIR" >&2
            exit 1
        fi
    else
        link_packages_manual
    fi
}

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
        echo "  Removing old symlink: $old -> $(readlink "$old")"
        record_removed_symlink "$old"
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
        echo "  Removing old symlink: $old -> $(readlink "$old")"
        record_removed_symlink "$old"
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
        backup_path "$target"
    fi
done
# Also handle directories and stale symlinks for stow-managed dirs
for dir in "$REAL_HOME/.config/nvim" "$REAL_HOME/.config/zsh"; do
    if [[ -L "$dir" ]]; then
        # Stale symlink — record where it pointed, then remove so stow can recreate it
        echo "  Removing stale symlink: $dir -> $(readlink "$dir")"
        record_removed_symlink "$dir"
        rm "$dir"
    elif [[ -d "$dir" ]]; then
        backup_path "$dir"
    fi
done

if [[ -d "$BACKUP_DIR" ]]; then
    echo "  Backups saved to: $BACKUP_DIR"
fi

# Link packages into ~ (uses GNU Stow if available, else a stow-free fallback
# so this works on machines without stow — e.g. a corporate Mac without brew).
echo ""
link_packages

# Generate a machine-specific tmux local.conf placeholder (sourced by tmux.conf).
# No AI assistant keybindings are configured.
TMUX_LOCAL="$REAL_HOME/.config/tmux/local.conf"
if [[ -f "$TMUX_LOCAL" ]]; then
    echo "tmux local.conf already exists, leaving it as-is: $TMUX_LOCAL"
else
    cat > "$TMUX_LOCAL" <<'EOF'
# Machine-specific tmux config (generated by install.sh)
# Add host-specific settings here.
EOF
    echo "Generated $TMUX_LOCAL"
fi

# Git identity prompt
GIT_LOCAL="$REAL_HOME/.config/git/config.local"
if [[ ! -f "$GIT_LOCAL" ]]; then
    echo ""
    echo "Setting up git identity..."
    git_name=""
    git_email=""
    read -r -p "Your full name (for git commits): " git_name || true
    read -r -p "Your email (matching your GitHub account): " git_email || true
    if [[ -n "$git_name" && -n "$git_email" ]]; then
        cat > "$GIT_LOCAL" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
        echo "Created $GIT_LOCAL"
    else
        echo "Skipped git identity (no input given). Create it later at $GIT_LOCAL"
    fi
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
command -v starship &>/dev/null && eval "\$(starship init zsh)"
# <<< dotfiles <<<
EOF
    echo "Added loader block to ~/.zshrc"
fi

# ===========================================================================
# TPM + Treesitter parsers — these fetch/compile things, so they're skipped in
# --configs-only mode. Run a full ./install.sh once the tools are available.
# ===========================================================================
if [[ "$CONFIGS_ONLY" == false ]]; then

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

fi   # end: TPM + Treesitter (skipped in --configs-only)

echo ""
echo "Done!"

NOTES=()
if [[ "$CONFIGS_ONLY" == true ]]; then
    NOTES+=("  - Configs are linked. Install the tools yourself when you can (no Homebrew needed for the configs themselves).")
    NOTES+=("  - Re-run './install.sh' (without --configs-only) on a machine where you can install tooling to set up TPM/Treesitter.")
fi
if [[ ! -d "$REAL_HOME/.tmux/plugins/catppuccin" ]]; then
    NOTES+=("  - In tmux, press prefix + I to install plugins")
fi
if [[ ${#NOTES[@]} -gt 0 ]]; then
    echo ""
    echo "Next steps:"
    printf '%s\n' "${NOTES[@]}"
fi
