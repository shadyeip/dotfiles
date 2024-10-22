# dotfiles

## Install

1. Clone repo and overwrite existing dotfiles:

```
cd ~ && git clone https://github.com/shadyeip/dotfiles.git && cp -rf dotfiles/.* . && rm -rf dotfiles && rm -f README.md && rm -f LICENSE
```

2. Add this to .zshrc:

```
# export CUSTOM_HOSTNAME=""
# export CUSTOM_USERNAME=""
# export IS_SAFE_MACHINE=true

# Load core settings
for file in ~/.zsh/*.zsh; do
    source "$file"
done
```

## Update

1. Run:

```
dotfiles_update
```