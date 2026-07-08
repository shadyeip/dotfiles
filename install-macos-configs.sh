#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# macOS config-only installer
#
# For Macs where you CAN'T install Homebrew (e.g. a locked-down corporate
# machine). It only links the dotfiles configs into ~/.config and wires up the
# ~/.zshrc loader — it installs NO packages and depends on NOTHING beyond the
# tools macOS already ships (bash, ln, git). In particular it does NOT need
# `stow`, so it works without brew.
#
# What it does:
#   - Symlinks the config packages (git, tmux, nvim, starship, ghostty, zsh)
#     into ~/.config, backing up anything real that's in the way.
#   - Adds the dotfiles loader block to ~/.zshrc.
#   - Generates ~/.config/tmux/local.conf and prompts for your git identity.
#   - Clones TPM (tmux plugin manager) if git is available.
#
# What it deliberately does NOT do (that install.sh does):
#   - Install any packages (zsh, neovim, starship, fzf, ripgrep, node, go, ...).
#   - Change your login shell (macOS already defaults to zsh).
#   - Compile Neovim Treesitter parsers (needs neovim + a compiler).
#
# The shell config degrades gracefully when a tool is missing, so an
# unstyled-but-working shell comes up immediately; install the individual
# tools by whatever means your machine allows (a managed self-service portal,
# a prebuilt binary in ~/.local/bin, etc.) and they light up on next shell.
# ---------------------------------------------------------------------------

ASSUME_YES=false
VERIFY=false

usage() {
    cat <<'EOF'
Usage: ./install-macos-configs.sh [options]

Links the dotfiles configs into ~/.config without installing any packages.
Intended for macOS machines without Homebrew (no `stow` required).

Options:
  --verify    Check that the config symlinks are in place, then exit
  -y, --yes   Assume "yes" to all confirmation prompts (non-interactive)
  -h, --help  Show this help and exit
EOF
}

for arg in "$@"; do
    case "$arg" in
        --verify) VERIFY=true ;;
        -y|--yes) ASSUME_YES=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

confirm() {
    if [[ "$ASSUME_YES" == true ]]; then
        return 0
    fi
    local reply
    if ! read -r -p "$1 [y/N]: " reply; then
        echo
        return 1
    fi
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
BACKUP_DIR="$HOME_DIR/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Config packages to link. Same set install.sh stows on macOS, and since this
# script is macOS-only, ghostty is always included.
PACKAGES=(git tmux nvim starship ghostty zsh)

# List the files a package would install, as paths relative to the package
# root (e.g. ".config/git/config"). We link files individually rather than
# folding directories, so runtime-generated files (zsh plugins, tmux local
# state, nvim's lazy-lock) land in real dirs under ~/.config, not in the repo.
package_rel_paths() {
    local pkg="$1"
    ( cd "$DOTFILES/$pkg" && find . -type f | sed 's|^\./||' )
}

# --verify mode: just check the symlinks, no dependency checks.
if [[ "$VERIFY" == true ]]; then
    echo "Verifying config symlinks..."
    errors=0
    for pkg in "${PACKAGES[@]}"; do
        while IFS= read -r rel; do
            [[ -z "$rel" ]] && continue
            dst="$HOME_DIR/$rel"
            want="$DOTFILES/$pkg/$rel"
            if [[ -L "$dst" && "$(readlink "$dst")" == "$want" ]]; then
                echo "  [ok] $dst"
            elif [[ -e "$dst" ]]; then
                echo "  [WRONG] $dst (exists but is not linked to this repo)"
                errors=$((errors + 1))
            else
                echo "  [MISSING] $dst"
                errors=$((errors + 1))
            fi
        done < <(package_rel_paths "$pkg")
    done

    if grep -qF "# >>> dotfiles >>>" "$HOME_DIR/.zshrc" 2>/dev/null; then
        echo "  [ok] zshrc loader block"
    else
        echo "  [MISSING] zshrc loader block"
        errors=$((errors + 1))
    fi

    if [[ -f "$HOME_DIR/.config/git/config.local" ]]; then
        echo "  [ok] git identity (config.local)"
    else
        echo "  [MISSING] git identity (~/.config/git/config.local)"
        errors=$((errors + 1))
    fi

    echo ""
    if [[ $errors -eq 0 ]]; then
        echo "All config checks passed."
    else
        echo "$errors issue(s) found. Run ./install-macos-configs.sh to fix."
    fi
    exit $errors
fi

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Note: this script is intended for macOS (detected OSTYPE='$OSTYPE')."
    echo "On Linux, use ./install.sh instead."
    confirm "Continue anyway?" || exit 0
fi

echo "Linking configs from $DOTFILES into $HOME_DIR (no packages will be installed)"
echo ""

# ---------------------------------------------------------------------------
# Backup + link helpers. Anything real that's in the way is moved into
# $BACKUP_DIR before we create a symlink; stale symlinks are just replaced.
# ---------------------------------------------------------------------------
backup_path() {
    local target="$1"
    mkdir -p "$BACKUP_DIR/$(dirname "${target#"$HOME_DIR"/}")"
    echo "  Backing up: $target"
    mv "$target" "$BACKUP_DIR/${target#"$HOME_DIR"/}"
}

link_file() {
    local src="$1" dst="$2"
    if [[ -L "$dst" ]]; then
        if [[ "$(readlink "$dst")" == "$src" ]]; then
            return 0   # already correctly linked
        fi
        rm "$dst"      # stale/other symlink — replace it
    elif [[ -e "$dst" ]]; then
        backup_path "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "  linked $dst"
}

for pkg in "${PACKAGES[@]}"; do
    echo "Linking $pkg..."
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        link_file "$DOTFILES/$pkg/$rel" "$HOME_DIR/$rel"
    done < <(package_rel_paths "$pkg")
done

if [[ -d "$BACKUP_DIR" ]]; then
    echo ""
    echo "Backups saved to: $BACKUP_DIR"
fi

# ---------------------------------------------------------------------------
# tmux local.conf placeholder (sourced by tmux.conf).
# ---------------------------------------------------------------------------
TMUX_LOCAL="$HOME_DIR/.config/tmux/local.conf"
if [[ -f "$TMUX_LOCAL" ]]; then
    echo ""
    echo "tmux local.conf already exists, leaving it as-is: $TMUX_LOCAL"
else
    cat > "$TMUX_LOCAL" <<'EOF'
# Machine-specific tmux config (generated by install-macos-configs.sh)
# Add host-specific settings here.
EOF
    echo ""
    echo "Generated $TMUX_LOCAL"
fi

# ---------------------------------------------------------------------------
# Git identity.
# ---------------------------------------------------------------------------
GIT_LOCAL="$HOME_DIR/.config/git/config.local"
if [[ ! -f "$GIT_LOCAL" ]]; then
    echo ""
    echo "Setting up git identity..."
    read -r -p "Your full name (for git commits): " git_name
    read -r -p "Your email (matching your GitHub account): " git_email
    cat > "$GIT_LOCAL" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
    echo "Created $GIT_LOCAL"
else
    echo "Git identity already configured ($GIT_LOCAL)"
fi

# ---------------------------------------------------------------------------
# Zshrc loader block.
# ---------------------------------------------------------------------------
ZSHRC="$HOME_DIR/.zshrc"
MARKER="# >>> dotfiles >>>"

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

# ---------------------------------------------------------------------------
# TPM (tmux plugin manager). git ships with the Xcode Command Line Tools, so
# this usually works even without brew; skipped cleanly if git is absent.
# ---------------------------------------------------------------------------
TPM_DIR="$HOME_DIR/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
    echo "TPM already installed"
elif command -v git &>/dev/null; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "git not found — skipping TPM. Install it later, then:"
    echo "  git clone https://github.com/tmux-plugins/tpm \"$TPM_DIR\""
fi

echo ""
echo "Done — configs are linked."
echo ""
echo "This script installed no packages. The shell config works with whatever"
echo "tools are present and degrades gracefully for those that aren't."
echo "For the full experience, get these onto your machine however you can"
echo "(self-service portal, prebuilt binaries in ~/.local/bin, etc.):"
echo "  zsh (preinstalled on macOS), starship, tmux, neovim, fzf, ripgrep, node, go"
echo ""
echo "Next steps:"
echo "  - Restart your terminal (or: source ~/.zshrc)"
echo "  - zsh plugins auto-install on first shell load (needs git)"
echo "  - In tmux, press prefix + I to install tmux plugins"
