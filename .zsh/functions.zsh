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
 
 echo "Copying new dotfiles..."
 for file in dotfiles/.[!.]*; do
   base_name=$(basename "$file")
   if [[ "$base_name" != ".git" ]] && 
      [[ "$base_name" != "README.md" ]] && 
      [[ "$base_name" != "LICENSE" ]]; then
     cp -rf "$file" .
   fi
 done
 
 rm -rf dotfiles
 
 echo "\n✨ Dotfiles successfully updated"
 echo "💡 Tip: You may need to restart your shell for changes to take effect"
}

alias update_dotfiles=dotfiles_update

setup_gcp_env() {
    local project=$1
    
    if [[ -z "$project" ]]; then
        project=$(gcloud config get-value project 2>/dev/null)
        if [[ -z "$project" ]]; then
            echo "Error: No project specified and no active project found"
            return 1
        fi
    fi
    
    echo "🔍 Setting up environment for project: $project"
    
    # Switch to project if needed
    if [[ "$(gcloud config get-value project 2>/dev/null)" != "$project" ]]; then
        gcloud config set project "$project" || return 1
    fi
    
    # Network
    echo "Getting network info..."
    export NETWORK=$(gcloud compute networks list --format="value(name)" --limit=1)
    if [[ -z "$NETWORK" ]]; then
        echo "⚠️  No networks found"
        return 1
    fi
    
    # Subnet and Region
    echo "Getting subnet info..."
    local subnet_info=$(gcloud compute networks subnets list --format="value(name,region)" --limit=1)
    if [[ -z "$subnet_info" ]]; then
        echo "⚠️  No subnets found"
        return 1
    fi
    
    export SUBNET=$(echo "$subnet_info" | awk '{print $1}')
    export REGION=$(echo "$subnet_info" | awk '{print $2}' | sed 's|.*/||')
    
    # Zone
    echo "Getting zone info..."
    export ZONE=$(gcloud compute zones list \
        --filter="region=$REGION" \
        --format="value(name)" \
        --limit=1)
    
    # Print summary
    echo "\n✨ Environment variables set:"
    echo "PROJECT=$project"
    echo "NETWORK=$NETWORK"
    echo "SUBNET=$SUBNET"
    echo "REGION=$REGION"
    echo "ZONE=$ZONE"
    
    # Optional: add to KUBECONFIG if GKE clusters exist
    if gcloud container clusters list --format="value(name)" --limit=1 2>/dev/null; then
        echo "\n💡 Tip: GKE clusters found. Use 'gcloud-get-credentials <cluster>' to set up kubectl"
    fi
}

# Add an alias for easier access
alias gcloud-setup-env='setup_gcp_env'