# dotfiles

## Install

1. Add this to .zshrc:

```
# export CUSTOM_HOSTNAME=""
# export CUSTOM_USERNAME=""
# export IS_SAFE_MACHINE=true

# Load core settings
for file in ~/.zsh/*.zsh; do
    source "$file"
done
```
