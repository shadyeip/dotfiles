# zsh-syntax-highlighting must be sourced after all widgets/keybindings are defined
ZSH_PLUGIN_DIR="${HOME}/.config/zsh/plugins"
[[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
