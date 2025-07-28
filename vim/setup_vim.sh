#!/bin/bash

source ./scripts/common.sh

install_vim() {
    if ! command_exists vim; then
        sudo apt install -y vim
    fi
    log_info "Install Vim"
}

configure_vim() {

    git clone --depth=1 https://github.com/amix/vimrc.git $HOME/.vim_runtime
    sh $HOME/.vim_runtime/install_awesome_vimrc.sh


    log_info "VIM configuration completed."
}

if command_exists vim; then
    configure_vim
else
    install_vim
    configure_vim
fi
