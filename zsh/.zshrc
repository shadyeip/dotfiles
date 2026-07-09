# ~/.zshrc — Oh My Zsh based configuration.
# Managed in the dotfiles repo and symlinked here by install.sh (stow).
# Keep personal, machine-specific tweaks in ~/.zshrc.local (untracked).

# --- Oh My Zsh -------------------------------------------------------------
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

# agnoster shows dir + git status like the old Starship prompt did, and it
# prints "user@host" over SSH so you always know whether you're on the Mac or
# the Linux box. It needs a Nerd/powerline font (the Ghostty config ships one).
# Prefer something plain? Set ZSH_THEME="robbyrussell" in ~/.zshrc.local.
ZSH_THEME="agnoster"

# Hide "user@host" on the local machine; agnoster still shows it inside SSH.
DEFAULT_USER="$USER"

# Oh My Zsh + community plugins. The two zsh-* plugins are external and cloned
# into $ZSH/custom/plugins by install.sh. Plugins for tools you don't have
# installed are harmless — they just add completions/aliases when present.
plugins=(
  git
  tmux
  fzf
  docker
  kubectl
  golang
  terraform
  gcloud
  python
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# --- Environment -----------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim" VISUAL="nvim"
  alias vim="nvim"
else
  export EDITOR="vim" VISUAL="vim"
fi
export PAGER="less"

# On Linux, pick up Homebrew if it's installed (adds brew's bin to PATH).
if [[ "$OSTYPE" == linux-gnu* && -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# --- Aliases ---------------------------------------------------------------
# Oh My Zsh's git/tmux/docker/etc. plugins already provide the common aliases
# (gst, gaa, gcmsg, gp, ta, ts, ...). Only add what they don't.
alias c="clear"
alias work="tmux new-session -A -s work"   # attach to (or create) a "work" session

# --- Functions -------------------------------------------------------------
# Stage everything, commit with the given message, and push.
gitcp() { git add -A && git commit -m "$1" && git push; }

# Epoch seconds -> human date in UTC (portable across macOS and Linux).
epoch2date() {
  if [[ "$OSTYPE" == linux-gnu* ]]; then
    date -d "@$1" -u "+%a %Y-%m-%d %H:%M:%S UTC"
  else
    date -r "$1" -u "+%a %Y-%m-%d %H:%M:%S UTC"
  fi
}

# --- Machine-specific overrides (untracked) --------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
