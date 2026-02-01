# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Editor
export EDITOR=vim
export VISUAL=vim
export PAGER=less

# Locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Terminal
export TERM=xterm-256color

# PATH
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Homebrew (Apple Silicon + Intel)
    if [[ -d /opt/homebrew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d /usr/local/Homebrew ]]; then
        eval "$(/usr/local/Homebrew/bin/brew shellenv)"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linuxbrew
    if [[ -d /home/linuxbrew/.linuxbrew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    # Snap
    if [[ -d /snap/bin ]]; then
        export PATH="/snap/bin:$PATH"
    fi
fi

# Local bin
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Starship
export STARSHIP_CONFIG=~/.config/starship.toml
