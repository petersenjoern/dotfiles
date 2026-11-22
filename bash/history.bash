# Shell history for bash on Debian servers: fzf (Ctrl-T files, Alt-C cd) + atuin (Ctrl-R, Up).
# Sourced from ~/.bashrc; installed by dev-env-bash.

[ -f "$HOME/.dotfiles.local.conf" ] && . "$HOME/.dotfiles.local.conf"
[ -n "$REMOTE_TAILNET" ] && export ATUIN_SYNC_ADDRESS="https://atuin.$REMOTE_TAILNET"
export PATH="$HOME/.atuin/bin:$PATH"

[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
# atuin's bash hooks need bash-preexec; loaded after fzf so atuin keeps Ctrl-R.
if [ -f "$HOME/.bash-preexec.sh" ] && command -v atuin >/dev/null; then
    . "$HOME/.bash-preexec.sh"
    eval "$(atuin init bash)"
fi
