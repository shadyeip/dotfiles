# dotfiles

## Install

1. Clone repo and overwrite existing dotfiles:

```
cd ~ && \
git clone https://github.com/shadyeip/dotfiles.git && \
cp -rf dotfiles/.* . && \
rm -rf dotfiles && \
rm -f README.md && \
rm -f LICENSE && \
echo "\n✨ Dotfiles successfully installed" && \
echo "💡 Remember to add these to your .zshrc:" && \
echo "# export CUSTOM_HOSTNAME=\"\"" && \
echo "# export CUSTOM_USERNAME=\"\"" && \
echo "# export IS_SAFE_MACHINE=true" && \
echo "" && \
echo "# Load core settings" && \
echo "for file in ~/.zsh/*.zsh; do" && \
echo "    source \"\$file\"" && \
echo "done" && \
echo "\n💡 Tip: You may need to restart your shell for changes to take effect"
```

## Update

1. Run:

```
dotfiles_update
# or
update_dotfiles
```