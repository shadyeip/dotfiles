# Zsh plugins
# Clone plugins if missing, then source them

ZSH_PLUGIN_DIR="${HOME}/.config/zsh/plugins"

# Install a plugin from GitHub if not already cloned
_zsh_plugin_install() {
    local repo="$1"
    local name="${repo##*/}"
    if [[ ! -d "$ZSH_PLUGIN_DIR/$name" ]]; then
        echo "Installing zsh plugin: $name..."
        mkdir -p "$ZSH_PLUGIN_DIR"
        git clone --depth 1 "https://github.com/$repo.git" "$ZSH_PLUGIN_DIR/$name"
    fi
}

# zsh-autosuggestions — fish-like inline command suggestions
_zsh_plugin_install "zsh-users/zsh-autosuggestions"
source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting — colorize commands as you type
_zsh_plugin_install "zsh-users/zsh-syntax-highlighting"
source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# fzf keybindings and completions
if command -v fzf &>/dev/null; then
    eval "$(fzf --zsh 2>/dev/null)" || {
        # Fallback for older fzf versions
        local fzf_base
        if [[ -d /opt/homebrew/opt/fzf ]]; then
            fzf_base="/opt/homebrew/opt/fzf"
        elif [[ -d /usr/local/opt/fzf ]]; then
            fzf_base="/usr/local/opt/fzf"
        elif [[ -d /usr/share/fzf ]]; then
            fzf_base="/usr/share/fzf"
        fi
        [[ -f "$fzf_base/shell/key-bindings.zsh" ]] && source "$fzf_base/shell/key-bindings.zsh"
        [[ -f "$fzf_base/shell/completion.zsh" ]] && source "$fzf_base/shell/completion.zsh"
    }
fi
