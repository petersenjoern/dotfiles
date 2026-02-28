#!/usr/bin/env bash
# Claude Code status line script
# Mirrors a Starship-style prompt: user@host  cwd  model  context%

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Build context indicator
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  ctx_str="ctx:${used_int}%"
else
  ctx_str="ctx:--"
fi

printf "\033[32m%s@%s\033[0m  \033[34m%s\033[0m  \033[33m%s\033[0m  \033[36m%s\033[0m" \
  "$(whoami)" "$(hostname -s)" "$short_cwd" "$model" "$ctx_str"
