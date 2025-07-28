#!/bin/bash

source ./scripts/common.sh

install_nvim() {
    if ! command_exists nvim; then
        sudo apt install -y neovim
    fi
    log_info "Install NeoVim"
}

configure_vim() {

    # Clone the Vundle repository
    clone_repo "https://github.com/VundleVim/Vundle.vim.git" "$HOME/.vim/bundle/Vundle.vim"
    ensure_directory "$HOME/.config/nvim"
    create_symlink "$HOME/dotfiles/vim/init.vim" "$HOME/.config/nvim/init.vim"
    # Install VIM plugins using Vundle
    vim +PluginInstall +qall

    log_info "VIM configuration completed."
}

if command_exists nvim; then
    log_info "NeoVim is already installed."
else
    install_nvim
fi
