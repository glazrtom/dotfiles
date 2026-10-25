message_info "Installing ZSH"

install zsh zsh-syntax-highlighting zsh-autosuggestions eza

"$DOTFILES_SETUP_SCRIPTS/install_fastfetch.sh"

link "$DOTFILES_ZSH/.zshrc" "$SETUP_HOME/.zshrc"
link "$DOTFILES_ZSH/.p10k.zsh" "$SETUP_HOME/.p10k.zsh"

[[ "$SHELL" != *zsh* ]] && chsh -s /bin/zsh < /dev/tty

message_done "ZSH setup done"
