# tmux
alias work='tmux new-session -s work || tmux attach -t work'
alias sls='tmux ls'
alias ss='tmux new -s $1'
alias sc='tmux attach -t $1'
alias sq='tmux kill-session -t $1'

# Navigation
setopt auto_cd
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# clear terminal
alias cls=clear
alias c=clear

# List directory contents
setup_ls_colors() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        alias ls='ls --color=auto'
        alias l='ls -l --color=auto'
        alias ll='ls -ltr --color=auto'
        alias la='ls -la --color=auto'
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        alias ls='ls -G'
        alias l='ls -lG'
        alias ll='ls -lGtr'
        alias la='ls -laG'
    else
        alias ls='ls -G'
        alias l='ls -lG'
        alias ll='ls -lGtr'
        alias la='ls -laG'
    fi
}
setup_ls_colors

setup_grep_colors() {
   if [[ "$OSTYPE" == "linux-gnu"* ]]; then
       alias grep='grep --color=auto'
       alias egrep='egrep --color=auto'
       alias fgrep='fgrep --color=auto'
   elif [[ "$OSTYPE" == "darwin"* ]]; then
       export GREP_OPTIONS='--color=auto'
       alias grep='grep --color=auto'
       alias egrep='egrep --color=auto'
       alias fgrep='fgrep --color=auto'
   else
       export GREP_OPTIONS='--color=auto'
       alias grep='grep --color=auto'
       alias egrep='egrep --color=auto'
       alias fgrep='fgrep --color=auto'
   fi
}
setup_grep_colors

# Git shortcuts
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"

# IP addresses
alias ip-egress="curl icanhazip.com -4"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    alias ip-local="ip route get 1 | awk '{print \$7; exit}'"
else
    alias ip-local="ipconfig getifaddr en0"
fi

# Quick edit for configuration files
alias zshconfig="vim ~/.zshrc"
alias sshconfig="vim ~/.ssh/config"

# Quick encode/decode functions
alias url-encode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
alias url-decode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'
alias base64-encode='python3 -c "import sys, base64; print(base64.b64encode(sys.argv[1].encode()).decode())"'
alias base64-decode='python3 -c "import sys, base64; print(base64.b64decode(sys.argv[1]).decode())"'

# python
alias pdb="python3 -m pdb"

# neovim
if command -v nvim &>/dev/null; then
    alias vim=nvim
fi

# gcloud
# Auth
alias gcloud-login='gcloud auth login'
alias gcloud-list-auth='gcloud auth list'
alias gcloud-list-configs='gcloud config configurations list'
# Project management
alias gcloud-list-projects='gcloud projects list'
alias gcloud-get-project='gcloud config get-value project'
alias gcloud-set-project='gcloud config set project'
# Compute Engine
alias gcloud-list-instances='gcloud compute instances list'
alias gcloud-list-regions='gcloud compute regions list'
alias gcloud-list-zones='gcloud compute zones list'
alias gcloud-ssh='gcloud compute ssh'
alias gcloud-ssh-tunnel='gcloud compute ssh --tunnel-through-iap'
# Kubernetes/GKE
alias gcloud-list-clusters='gcloud container clusters list'
alias gcloud-get-credentials='gcloud container clusters get-credentials'
# IAM
alias gcloud-list-roles='gcloud iam roles list'
alias gcloud-list-service-accounts='gcloud iam service-accounts list'
