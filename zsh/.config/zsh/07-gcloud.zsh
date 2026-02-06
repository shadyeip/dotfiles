# gcloud aliases (only loaded if gcloud is installed)
if ! command -v gcloud &>/dev/null; then
    return
fi

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
