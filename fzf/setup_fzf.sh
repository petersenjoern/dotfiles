#!/bin/bash
source ./scripts/common.sh

install_fzf() {
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all

    log_info "Installed FZF"
}

configure_fzf() {
    log_info "Fzf configuration completed."
}

if command_exists fzf; then
    configure_fzf
else
    install_fzf
    configure_fzf
fi