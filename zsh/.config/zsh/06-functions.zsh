# Docker cleanup
docker-cleanup() {
    docker container prune -f
    docker image prune -f
    docker network prune -f
    docker volume prune -f
}

# Git commit and push in one command
gitcp() {
    git add .
    git commit -m "$1"
    git push
}

# Find process by name
psfind() {
    ps aux | grep "$@" | grep -v grep
}

# Show disk usage of current directory
duf() {
    du -sh * | ls -lrhS
}

# Find file under the current directory
ff() {
    find . |grep --color $@
}

# Search command history
hgrep() {
    history | grep "$@"
}

epoch2date() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        date -d "@$1" -u "+%a %Y-%m-%d %H:%M:%S UTC"
    else
        date -r "$1" -u "+%a %Y-%m-%d %H:%M:%S UTC"
    fi
}

dotfiles_update() {
    local dotfiles_dir
    dotfiles_dir="$(readlink ~/.config/zsh)"
    dotfiles_dir="${dotfiles_dir%/zsh/.config/zsh}"

    if [[ ! -d "$dotfiles_dir/.git" ]]; then
        echo "Error: Could not find dotfiles repo at $dotfiles_dir"
        return 1
    fi

    echo "Updating dotfiles from $dotfiles_dir..."
    git -C "$dotfiles_dir" pull || { echo "Error: git pull failed"; return 1; }

    echo ""
    if "$dotfiles_dir/install.sh" --verify; then
        echo ""
        echo "Dotfiles updated. Reloading..."
        source ~/.zshrc
    else
        echo ""
        echo "Issues found. Run: $dotfiles_dir/install.sh"
    fi
}

alias dotup=dotfiles_update
alias update_dotfiles=dotfiles_update
