#!/usr/bin/env bash
# Notification hook: desktop notification naming the tmux window Claude runs
# in; on Omarchy, clicking it focuses that pane.

message=$(jq -r '.message // "Awaiting your input"')
headline="Claude Code"
click=()

if [[ -n $TMUX_PANE ]]; then
    read -r active title < <(tmux display -p -t "$TMUX_PANE" '#{pane_active}#{window_active}#{?session_attached,1,0} #T')
    # Skip when the focused terminal already shows this pane.
    [[ $active == 111 && $(hyprctl activewindow -j 2>/dev/null | jq -r .title) == "$title" ]] && exit 0
    headline+=" · $(tmux display -p -t "$TMUX_PANE" '#S:#W')"
    click=(--exec "$HOME/.local/scripts/tmux-focus" "$TMUX_PANE")
fi

if command -v omarchy-notification-send >/dev/null; then
    omarchy-notification-send -u normal "$headline" "$message" "${click[@]}"
else
    notify-send "$headline" "$message"
fi
