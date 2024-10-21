# File: ~/.zsh/keybindings.zsh

# Word navigation for macOS
# bindkey "^[[1;3C" forward-word   # Option + Right Arrow
# bindkey "^[[1;3D" backward-word  # Option + Left Arrow

# Alternative, some terminals might need these instead
bindkey "[C" forward-word      # Option + Right Arrow
bindkey "[D" backward-word     # Option + Left Arrow

# Beginning and end of line
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

# History search
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward

# Up/down line or search
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search