# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# Environment variables
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export TERM='xterm-256color'

# Conditional PATH additions (Homebrew on macOS is handled by .zprofile)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    [[ -d /usr/local/bin ]] && export PATH="/usr/local/bin:$PATH"
    [[ -d /snap/bin ]] && export PATH="/snap/bin:$PATH"
    # Linuxbrew
    [[ -d /home/linuxbrew/.linuxbrew/bin ]] && export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi
