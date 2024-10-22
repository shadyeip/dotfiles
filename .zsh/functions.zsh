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
    date -r "$1" -u "+%a %Y-%m-%d %H:%M:%S UTC"
}

dotfiles_update() {
 echo "Updating dotfiles from shadyeip/dotfiles..."
 
 cd ~ || { echo "Error: Could not change to home directory"; return 1; }
 
 git clone https://github.com/shadyeip/dotfiles.git || { 
   echo "Error: Failed to clone repository"; return 1; 
 }
 
 cp -rf dotfiles/.[!.]* . || { 
   echo "Error: Failed to copy files"; rm -rf dotfiles; return 1; 
 }
 
 rm -rf dotfiles
 
 echo "\n✨ Dotfiles successfully updated"
 echo "💡 Tip: You may need to restart your shell for changes to take effect"
}