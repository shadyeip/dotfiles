# oh-my-zsh — see README for install instructions
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting)

# Custom config, sourced before oh-my-zsh so its zstyles/exports are in
# place before oh-my-zsh runs compinit and loads plugins.
for f in ~/.config/zsh/*.zsh; do source "$f"; done

source "$ZSH/oh-my-zsh.sh"
