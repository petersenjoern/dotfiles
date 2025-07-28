#!/bin/bash

# tmux session and window names
TMUX_SESSION="JP"
TMUX_WINDOW_SERVICES="llm-services"
TMUX_WINDOW_OBSERVABILITY="observability"
PATH_TO_REPOS="$HOME/repos"
PATH_TO_DOTFILES="$HOME/repos/personal/dotfiles"

# Construct the commands for each model
OLLAMA_SHUTDOWN="systemctl stop ollama.service"
OLLAMA_SERVE="ollama serve"
OLLAMA_SERVE_PORT=11434
OLLAMA_RUN_MIXTRAL="ollama run phi3"
PIP_ACTIVATE="source venv/bin/activate"
LITELLM_SERVE="litellm --config ${PATH_TO_REPOS}/llm_serve/litellm-config.yaml"
TIMEOUT=30

# run services Pane indices
OLLAMA_SERVE_PANE_INDEX=1
OLLAMA_RUN_PANE_INDEX=2
LITELLM_PANE_INDEX=3

# Full target for tmux (session:window.pane) for ollama shutdown and serve
OLLAMA_SERVICE="${TMUX_SESSION}:${TMUX_WINDOW_SERVICES}.${OLLAMA_SERVE_PANE_INDEX}"

# Full target for tmux (session:window.pane) for ollama run
OLLAMA_MODEL="${TMUX_SESSION}:${TMUX_WINDOW_SERVICES}.${OLLAMA_RUN_PANE_INDEX}"

# Full target for tmux (session:window.pane) for litellm
LITELLM_SERVICE="${TMUX_SESSION}:${TMUX_WINDOW_SERVICES}.${LITELLM_PANE_INDEX}"

# Pane 0
# Send the shutdown command
tmux send-keys -t "$OLLAMA_SERVICE" "$OLLAMA_SHUTDOWN; tmux wait-for -S ollama_shutdown_done" C-m
tmux wait-for ollama_shutdown_done
# Send the serve command
tmux send-keys -t "$OLLAMA_SERVICE" "$OLLAMA_SERVE" C-m

# Pane 1
# Wait for the Serve to be running, then load the model
tmux send-keys -t "$OLLAMA_MODEL" "echo \"Ensuring that ollama serve is running on port $OLLAMA_SERVE_PORT\"" C-m
tmux send-keys -t "$OLLAMA_MODEL" "${PATH_TO_DOTFILES}/tmux/check_service_port.sh $OLLAMA_SERVE_PORT $TIMEOUT" C-m
tmux send-keys -t "$OLLAMA_MODEL" "$OLLAMA_RUN_MIXTRAL" C-m

# Pane 2
# Start litellm service
tmux send-keys -t "$LITELLM_SERVICE" "cd ${PATH_TO_REPOS}/llm_serve" C-m
tmux send-keys -t "$LITELLM_SERVICE" "$PIP_ACTIVATE" C-m
tmux send-keys -t "$LITELLM_SERVICE" "$LITELLM_SERVE" C-m

# observability pane indices
NVIDIA_SMI_PANE_INDEX=1
BTOP_PANE_INDEX=2

# Full target for tmux for watch nvidia-smi
WATCH_NVIDIA_SMI="${TMUX_SESSION}:${TMUX_WINDOW_OBSERVABILITY}.${NVIDIA_SMI_PANE_INDEX}"

# Full target for tmux for BTOP
BTOP_SERVICE="${TMUX_SESSION}:${TMUX_WINDOW_OBSERVABILITY}.${BTOP_PANE_INDEX}"

# Pane 0
tmux send-keys -t "$WATCH_NVIDIA_SMI" "watch -n 1 nvidia-smi" C-m

# Pane 1
tmux send-keys -t "$BTOP_SERVICE" "htop" C-m
