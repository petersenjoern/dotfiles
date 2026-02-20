Tail the tmux logs from pane $ARGUMENTS in the current tmux session and window.

Detect the current session and window by running:
- `tmux display-message -p '#S'` for the session name
- `tmux display-message -p '#I'` for the current window index

Then capture the last 500 lines or the amount of lines you deem resonable and
apply your bash knowledge to search filter etc.
`tmux capture-pane -t <session>:<window>.<pane> -p -S -500`

