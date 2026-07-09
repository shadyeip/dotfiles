#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# dotfiles installer
#
# Installs the tooling (via Homebrew on macOS / apt on Debian-Ubuntu), sets up
# Oh My Zsh + a couple of community plugins, and symlinks the configs into your
# home directory with GNU Stow. Re-run any time to repair things.
#
#   ./install.sh                # full install
#   ./install.sh --no-packages  # just link configs + Oh My Zsh (no pkg manager)
#   ./install.sh --verify       # check the install, change nothing
#   ./install.sh --yes          # answer "yes" to every prompt (unattended)
#
# Run it as your normal user (NOT with sudo); it calls sudo only where a step
# genuinely needs root (apt, editing /etc/shells).
# ---------------------------------------------------------------------------

ASSUME_YES=false
NO_PACKAGES=false
VERIFY=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --no-packages  Skip installing system packages (just Oh My Zsh + config links).
                 Useful on a locked-down machine without Homebrew/apt.
  --verify       Check symlinks and dependencies, then exit (no changes made).
  -y, --yes      Assume "yes" to all confirmation prompts (non-interactive).
  -h, --help     Show this help and exit.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --no-packages) NO_PACKAGES=true ;;
        --verify)      VERIFY=true ;;
        -y|--yes)      ASSUME_YES=true ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

confirm() {
    [[ "$ASSUME_YES" == true ]] && return 0
    local reply
    if ! read -r -p "$1 [y/N]: " reply; then echo; return 1; fi
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

OS="unknown"
case "$OSTYPE" in
    darwin*)     OS="macos" ;;
    linux-gnu*)  OS="linux" ;;
esac

# Ghostty is a GUI terminal — only stow it on the machine the terminal runs on
# (your Mac), not on a headless Linux box you SSH into.
STOW_PACKAGES=(git tmux nvim zsh)
[[ "$OS" == "macos" ]] && STOW_PACKAGES+=(ghostty)

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

# ---------------------------------------------------------------------------
# --verify: report status, change nothing.
# ---------------------------------------------------------------------------
if [[ "$VERIFY" == true ]]; then
    echo "Verifying dotfiles installation..."
    errors=0
    note_missing() { echo "  [MISSING] $1"; errors=$((errors + 1)); }

    for cmd in zsh stow nvim fzf rg git tmux; do
        command -v "$cmd" &>/dev/null && echo "  [ok] $cmd" || note_missing "$cmd"
    done

    [[ -d "$ZSH_DIR" ]] && echo "  [ok] Oh My Zsh" || note_missing "Oh My Zsh (~/.oh-my-zsh)"
    for p in zsh-autosuggestions zsh-syntax-highlighting; do
        [[ -d "$ZSH_CUSTOM_DIR/plugins/$p" ]] && echo "  [ok] plugin: $p" || note_missing "plugin: $p"
    done

    check_link() { [[ -L "$1" || -e "$1" ]] && echo "  [ok] $1" || note_missing "$1"; }
    check_link "$HOME/.zshrc"
    check_link "$HOME/.config/git/config"
    check_link "$HOME/.config/tmux/tmux.conf"
    check_link "$HOME/.config/nvim/init.lua"
    [[ "$OS" == "macos" ]] && check_link "$HOME/.config/ghostty/config"

    [[ -d "$HOME/.tmux/plugins/tpm" ]] && echo "  [ok] TPM" || note_missing "TPM"
    [[ -f "$HOME/.config/git/config.local" ]] && echo "  [ok] git identity" \
        || note_missing "git identity (~/.config/git/config.local)"

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
# 1. System packages
# ---------------------------------------------------------------------------
# The nvim config needs Neovim >= 0.11 (vim.lsp.config). Debian's apt package
# is far too old, so on Linux we grab the official release instead.
NVIM_MIN_MINOR=11
nvim_is_recent() {
    command -v nvim &>/dev/null || return 1
    local v; v="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    [[ -z "$v" ]] && return 1
    (( ${v%%.*} > 0 || ${v#*.} >= NVIM_MIN_MINOR ))
}

install_neovim_linux() {
    local arch tarch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)  tarch="x86_64" ;;
        aarch64|arm64) tarch="arm64" ;;
        *) echo "  Unsupported arch '$arch'; using apt neovim (may be too old)"; sudo apt install -y neovim; return ;;
    esac
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${tarch}.tar.gz"
    local tmp; tmp="$(mktemp -d)"
    echo "  Downloading official Neovim (${tarch})..."
    if curl -fsSL "$url" -o "$tmp/nvim.tar.gz"; then
        sudo rm -rf "/opt/nvim-linux-${tarch}"
        sudo tar -C /opt -xzf "$tmp/nvim.tar.gz"
        sudo ln -sf "/opt/nvim-linux-${tarch}/bin/nvim" /usr/local/bin/nvim
        echo "  Neovim installed to /opt/nvim-linux-${tarch}"
    else
        echo "  Download failed; falling back to apt neovim (may be too old)"
        sudo apt install -y neovim
    fi
    rm -rf "$tmp"
}

if [[ "$NO_PACKAGES" == true ]]; then
    echo "Skipping package installation (--no-packages)."
elif [[ "$OS" == "macos" ]]; then
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found. Install it (https://brew.sh) or re-run with --no-packages." >&2
        exit 1
    fi
    if confirm "Install packages from the Brewfile?"; then
        brew bundle --file="$DOTFILES/Brewfile"
    fi
elif [[ "$OS" == "linux" ]]; then
    if confirm "Install packages with 'sudo apt'?"; then
        sudo apt update
        # shellcheck disable=SC2046
        sudo apt install -y $(grep -vE '^\s*#' "$DOTFILES/apt-packages.txt")
        nvim_is_recent || install_neovim_linux
    fi
else
    echo "Unknown OS; skipping package install. Use --no-packages to silence this."
fi

# ---------------------------------------------------------------------------
# 2. Oh My Zsh + external plugins
# ---------------------------------------------------------------------------
if [[ -d "$ZSH_DIR" ]]; then
    echo "Oh My Zsh already installed"
elif confirm "Install Oh My Zsh?"; then
    installer="$(mktemp)"
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$installer"
    # KEEP_ZSHRC=yes so it doesn't clobber the .zshrc we stow; RUNZSH/CHSH=no
    # so it doesn't launch a shell or change the login shell mid-script.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$installer" --unattended
    rm -f "$installer"
fi

clone_plugin() {
    local repo="$1" dest="$ZSH_CUSTOM_DIR/plugins/${1##*/}"
    if [[ -d "$dest" ]]; then
        echo "  plugin ${1##*/} already installed"
    else
        echo "  Installing plugin ${1##*/}..."
        git clone --depth 1 "https://github.com/$repo.git" "$dest"
    fi
}
if [[ -d "$ZSH_DIR" ]]; then
    mkdir -p "$ZSH_CUSTOM_DIR/plugins"
    clone_plugin "zsh-users/zsh-autosuggestions"
    clone_plugin "zsh-users/zsh-syntax-highlighting"
fi

# ---------------------------------------------------------------------------
# 3. Symlink configs (stow, or a plain symlink fallback if stow is absent)
# ---------------------------------------------------------------------------
backup_path() {
    mkdir -p "$BACKUP_DIR"
    echo "  Backing up: $1 -> $BACKUP_DIR/"
    mv "$1" "$BACKUP_DIR/"
}

echo ""
echo "Cleaning up old symlinks from previous layouts..."
# The previous setup stowed ~/.config/zsh and used Starship — both are gone now.
for old in "$HOME/.config/zsh" "$HOME/.config/starship.toml"; do
    if [[ -L "$old" ]]; then
        echo "  Removing stale symlink: $old"
        rm "$old"
    fi
done

echo "Backing up any conflicting real files..."
CONFLICTS=(
    "$HOME/.zshrc"
    "$HOME/.config/git/config" "$HOME/.config/git/ignore"
    "$HOME/.config/tmux/tmux.conf"
    "$HOME/.config/nvim/init.lua" "$HOME/.config/nvim/lazy-lock.json"
    "$HOME/.config/ghostty/config"
)
for target in "${CONFLICTS[@]}"; do
    [[ -e "$target" && ! -L "$target" ]] && backup_path "$target"
done
if [[ -L "$HOME/.config/nvim" ]]; then
    echo "  Removing stale symlink: $HOME/.config/nvim"
    rm "$HOME/.config/nvim"
fi
[[ -d "$BACKUP_DIR" ]] && echo "  Backups saved to: $BACKUP_DIR"

echo ""
echo "Linking configs..."
if command -v stow &>/dev/null; then
    stow -v -t "$HOME" -d "$DOTFILES" "${STOW_PACKAGES[@]}"
else
    # No stow (e.g. locked-down --no-packages run): link each file by hand.
    echo "  stow not found — linking files directly."
    for pkg in "${STOW_PACKAGES[@]}"; do
        while IFS= read -r rel; do
            src="$DOTFILES/$pkg/$rel"; dst="$HOME/$rel"
            mkdir -p "$(dirname "$dst")"
            [[ -e "$dst" && ! -L "$dst" ]] && backup_path "$dst"
            ln -sfn "$src" "$dst"
            echo "  linked $dst"
        done < <(cd "$DOTFILES/$pkg" && find . -type f | sed 's|^\./||')
    done
fi

# ---------------------------------------------------------------------------
# 4. Default login shell -> zsh
# ---------------------------------------------------------------------------
ZSH_PATH="$(command -v zsh || true)"
CURRENT_SHELL=""
command -v getent &>/dev/null && CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 || true)"
[[ -z "$CURRENT_SHELL" && "$OS" == "macos" ]] && \
    CURRENT_SHELL="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}' || true)"

if [[ -z "$ZSH_PATH" ]]; then
    echo "zsh not on PATH; skipping default-shell change."
elif [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
    echo "Default shell already zsh"
elif confirm "Set your default login shell to zsh ($ZSH_PATH)?"; then
    if [[ "$OS" == "linux" ]] && ! grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$ZSH_PATH" || echo "  Could not change shell automatically. Run: chsh -s $ZSH_PATH"
fi

# ---------------------------------------------------------------------------
# 5. Git identity (kept out of the tracked config)
# ---------------------------------------------------------------------------
GIT_LOCAL="$HOME/.config/git/config.local"
if [[ -f "$GIT_LOCAL" ]]; then
    echo "Git identity already configured"
else
    echo ""
    echo "Setting up git identity..."
    read -r -p "  Your full name (for git commits): " git_name
    read -r -p "  Your email (matching your GitHub account): " git_email
    cat > "$GIT_LOCAL" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
    echo "  Created $GIT_LOCAL"
fi

# ---------------------------------------------------------------------------
# 6. TPM (tmux plugin manager)
# ---------------------------------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
    echo "TPM already installed"
else
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

echo ""
echo "Done!"
echo ""
echo "Next steps:"
echo "  - Restart your terminal (or: exec zsh)"
echo "  - In tmux, press prefix + I to install tmux plugins"
echo "  - Open nvim once; it installs its plugins, LSP servers, and Treesitter"
echo "    parsers on first launch"
