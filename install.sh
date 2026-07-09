#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# dotfiles installer
#
# Sets up Oh My Zsh + a couple of community plugins and symlinks the configs
# into your home directory. It installs as little as possible:
#
#   - It assumes zsh, tmux, and git are already present (they almost always are)
#     and never reinstalls them.
#   - On Linux it fetches only the tools this repo's configs actually use and
#     that usually aren't preinstalled — Neovim (needs >= 0.11), ripgrep, fzf —
#     as prebuilt binaries into ~/.local. No apt, no root.
#   - On macOS (a terminal host) it installs nothing at all.
#   - Anything else that's missing is reported, not installed.
#
#   ./install.sh                # install
#   ./install.sh --no-packages  # skip the ~/.local tool downloads too
#   ./install.sh --verify       # check the install, change nothing
#   ./install.sh --yes          # answer "yes" to every prompt (unattended)
# ---------------------------------------------------------------------------

ASSUME_YES=false
NO_PACKAGES=false
VERIFY=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --no-packages  Don't download any tools; just Oh My Zsh + config links.
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
LOCAL_BIN="$HOME/.local/bin"

OS="unknown"
case "$OSTYPE" in
    darwin*)     OS="macos" ;;
    linux-gnu*)  OS="linux" ;;
esac

# Ghostty is a GUI terminal — only link it on the machine the terminal runs on
# (your Mac), not on a headless Linux box you SSH into.
PACKAGES=(git tmux nvim zsh)
[[ "$OS" == "macos" ]] && PACKAGES+=(ghostty)

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

# ---------------------------------------------------------------------------
# --verify: report status, change nothing.
# ---------------------------------------------------------------------------
if [[ "$VERIFY" == true ]]; then
    echo "Verifying dotfiles installation..."
    errors=0
    note_missing() { echo "  [MISSING] $1"; errors=$((errors + 1)); }

    for cmd in zsh nvim git tmux; do
        command -v "$cmd" &>/dev/null && echo "  [ok] $cmd" || note_missing "$cmd"
    done
    for cmd in rg fzf; do
        command -v "$cmd" &>/dev/null && echo "  [ok] $cmd" || echo "  [absent] $cmd (optional)"
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

    if command -v tmux &>/dev/null; then
        [[ -d "$HOME/.tmux/plugins/tpm" ]] && echo "  [ok] TPM" || note_missing "TPM"
    fi
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
# 1. Tools (Linux only) — prebuilt binaries into ~/.local, no apt, no root.
# ---------------------------------------------------------------------------
NVIM_MIN_MINOR=11
nvim_is_recent() {
    command -v nvim &>/dev/null || return 1
    local v; v="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    [[ -z "$v" ]] && return 1
    (( ${v%%.*} > 0 || ${v#*.} >= NVIM_MIN_MINOR ))
}

# Resolve the latest release tag for a GitHub repo, no jq needed: read
# "tag_name" straight out of the releases API JSON.
gh_latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
        | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

install_neovim_local() {
    if nvim_is_recent; then echo "  neovim: ok ($(nvim --version | head -1))"; return; fi
    local tarch
    case "$(uname -m)" in
        x86_64|amd64)  tarch="x86_64" ;;
        aarch64|arm64) tarch="arm64" ;;
        *) echo "  neovim: unsupported arch $(uname -m); install manually"; return ;;
    esac
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${tarch}.tar.gz"
    local tmp; tmp="$(mktemp -d)"
    echo "  neovim: installing latest into ~/.local ..."
    if curl -fsSL "$url" -o "$tmp/nvim.tgz"; then
        rm -rf "$HOME/.local/nvim"; mkdir -p "$HOME/.local/nvim"
        tar -xzf "$tmp/nvim.tgz" -C "$HOME/.local/nvim" --strip-components=1
        ln -sfn "$HOME/.local/nvim/bin/nvim" "$LOCAL_BIN/nvim"
        echo "  neovim: ~/.local/nvim (linked at ~/.local/bin/nvim)"
    else
        echo "  neovim: download failed; install manually."
    fi
    rm -rf "$tmp"
}

install_ripgrep_local() {
    if command -v rg &>/dev/null; then echo "  ripgrep: ok"; return; fi
    local triple
    case "$(uname -m)" in
        x86_64|amd64)  triple="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) triple="aarch64-unknown-linux-gnu" ;;
        *) echo "  ripgrep: unsupported arch $(uname -m); install manually"; return ;;
    esac
    local ver; ver="$(gh_latest_tag BurntSushi/ripgrep)"
    [[ -z "$ver" ]] && { echo "  ripgrep: could not resolve latest version; skipping"; return; }
    local url="https://github.com/BurntSushi/ripgrep/releases/download/${ver}/ripgrep-${ver}-${triple}.tar.gz"
    local tmp; tmp="$(mktemp -d)"
    echo "  ripgrep: installing ${ver} into ~/.local/bin ..."
    if curl -fsSL "$url" -o "$tmp/rg.tgz" && tar -xzf "$tmp/rg.tgz" -C "$tmp"; then
        cp "$tmp"/ripgrep-*/rg "$LOCAL_BIN/rg" && chmod +x "$LOCAL_BIN/rg"
        echo "  ripgrep: ~/.local/bin/rg"
    else
        echo "  ripgrep: download failed; install manually."
    fi
    rm -rf "$tmp"
}

install_fzf_local() {
    if command -v fzf &>/dev/null; then echo "  fzf: ok"; return; fi
    local farch
    case "$(uname -m)" in
        x86_64|amd64)  farch="amd64" ;;
        aarch64|arm64) farch="arm64" ;;
        *) echo "  fzf: unsupported arch $(uname -m); install manually"; return ;;
    esac
    local tag ver; tag="$(gh_latest_tag junegunn/fzf)"; ver="${tag#v}"
    [[ -z "$ver" ]] && { echo "  fzf: could not resolve latest version; skipping"; return; }
    local url="https://github.com/junegunn/fzf/releases/download/${tag}/fzf-${ver}-linux_${farch}.tar.gz"
    local tmp; tmp="$(mktemp -d)"
    echo "  fzf: installing ${ver} into ~/.local/bin ..."
    if curl -fsSL "$url" -o "$tmp/fzf.tgz" && tar -xzf "$tmp/fzf.tgz" -C "$tmp"; then
        cp "$tmp/fzf" "$LOCAL_BIN/fzf" && chmod +x "$LOCAL_BIN/fzf"
        echo "  fzf: ~/.local/bin/fzf"
    else
        echo "  fzf: download failed; install manually."
    fi
    rm -rf "$tmp"
}

report_optional_deps() {
    local missing_core=() missing_opt=()
    for c in git zsh tmux; do command -v "$c" &>/dev/null || missing_core+=("$c"); done
    for c in cc node go; do command -v "$c" &>/dev/null || missing_opt+=("$c"); done
    if ((${#missing_core[@]})); then
        echo "  ! Expected but missing: ${missing_core[*]}"
        echo "    Install with your package manager, e.g.: sudo apt install ${missing_core[*]}"
    fi
    if ((${#missing_opt[@]})); then
        echo "  Optional (for full Neovim LSP + Treesitter): ${missing_opt[*]}"
        echo "    e.g.: sudo apt install gcc nodejs npm golang"
    fi
}

if [[ "$NO_PACKAGES" == true ]]; then
    echo "Skipping tool downloads (--no-packages)."
elif [[ "$OS" == "linux" ]]; then
    echo "Installing tools into ~/.local (no apt, no root)..."
    mkdir -p "$LOCAL_BIN"
    install_neovim_local
    install_ripgrep_local
    install_fzf_local
    report_optional_deps
elif [[ "$OS" == "macos" ]]; then
    echo "macOS host: nothing to install (zsh/git ship with macOS, Ghostty bundles the font)."
else
    echo "Unknown OS; skipping tool install."
fi

# ---------------------------------------------------------------------------
# 2. Oh My Zsh + external plugins (just git clones)
# ---------------------------------------------------------------------------
if [[ -d "$ZSH_DIR" ]]; then
    echo "Oh My Zsh already installed"
elif confirm "Install Oh My Zsh?"; then
    installer="$(mktemp)"
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$installer"
    # KEEP_ZSHRC=yes so it doesn't clobber the .zshrc we link; RUNZSH/CHSH=no
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
# 3. Link configs (plain symlinks — no stow dependency). Files are linked
#    individually so tools that write state next to their config (nvim's
#    lazy/, tmux local.conf) use a real dir under ~/.config, not the repo.
# ---------------------------------------------------------------------------
backup_path() {
    mkdir -p "$BACKUP_DIR"
    echo "  Backing up: $1 -> $BACKUP_DIR/"
    mv "$1" "$BACKUP_DIR/"
}

echo ""
echo "Cleaning up symlinks from previous layouts..."
# The previous setup stowed ~/.config/zsh and used Starship — both are gone now.
for old in "$HOME/.config/zsh" "$HOME/.config/starship.toml" "$HOME/.config/nvim"; do
    if [[ -L "$old" ]]; then
        echo "  Removing stale symlink: $old"
        rm "$old"
    fi
done

echo "Linking configs..."
for pkg in "${PACKAGES[@]}"; do
    while IFS= read -r rel; do
        src="$DOTFILES/$pkg/$rel"; dst="$HOME/$rel"
        if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
            continue
        elif [[ -L "$dst" ]]; then
            rm "$dst"
        elif [[ -e "$dst" ]]; then
            backup_path "$dst"
        fi
        mkdir -p "$(dirname "$dst")"
        ln -sfn "$src" "$dst"
        echo "  linked $dst"
    done < <(cd "$DOTFILES/$pkg" && find . -type f | sed 's|^\./||')
done
[[ -d "$BACKUP_DIR" ]] && echo "  Backups saved to: $BACKUP_DIR"

# ---------------------------------------------------------------------------
# 4. Default login shell -> zsh (only if it isn't already)
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
# 6. TPM (tmux plugin manager) — only if tmux is present
# ---------------------------------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if ! command -v tmux &>/dev/null; then
    echo "tmux not installed — skipping TPM."
elif [[ -d "$TPM_DIR" ]]; then
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
if command -v tmux &>/dev/null; then
    echo "  - In tmux, press prefix + I to install tmux plugins"
fi
if command -v nvim &>/dev/null || [[ "$OS" == "linux" ]]; then
    echo "  - Open nvim once; it installs its plugins, LSP servers, and Treesitter parsers"
fi
exit 0
