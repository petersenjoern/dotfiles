#!/usr/bin/env zsh

# Lazy-load 1Password secrets into env vars.
# Secrets are resolved on first call and cached for the session.
# Shell startup stays instant — 1Password only prompts when needed.
#
# Usage:
#   op_env ANTHROPIC_API_KEY "op://Personal/anthropic-api/credential"
#   op_load  # load all registered secrets at once

op_env() {
  local var="$1" ref="$2"
  if [[ -z "${(P)var}" ]]; then
    local val
    if val=$(op read "$ref" 2>/dev/null); then
      export "$var=$val"
    else
      echo "op_env: failed to read $ref" >&2
      return 1
    fi
  fi
}

op_load() {
  op_env ANTHROPIC_API_KEY "op://Personal/anthropic-amass-api-local-jp/credential"
  op_env AWS_BEARER_TOKEN_BEDROCK "op://Work/aws-bedrock/credential"
  op_env MODAL_TOKEN_ID "op://Work/modal-tagger-id/credential"
  op_env MODAL_TOKEN_SECRET "op://Work/modal-tagger-secret/credential"
}

# Kill processes named $1 whose cmdline contains $2. Matching on the name keeps
# `pkill -f "mise hook-env"` from killing the shell that ran it, and matching on
# the args spares an in-flight `mise install` or `op run`.
_1p_kill() {
  local pid killed=0
  for pid in ${(f)"$(pgrep -x $1)"}; do
    [[ "$(tr '\0' ' ' < /proc/$pid/cmdline 2> /dev/null)" == *$2* ]] || continue
    kill $pid 2> /dev/null && (( killed++ ))
  done
  (( killed )) && echo "  killed $killed stuck '$1 $2'"
  return 0
}

# Recover from a dismissed 1Password "developer environment file mount" dialog.
# Denying it quits the app, so mise blocks forever opening the .env.1password
# FIFO and every pane that cd's into the repo hangs with no prompt.
1p-unstick() {
  if command -v hyprctl > /dev/null &&
    hyprctl clients -j 2> /dev/null | grep -qi '"class": *"1password"'; then
    hyprctl dispatch focuswindow class:1password > /dev/null
    echo "1Password window was only buried — focused it"
    return
  fi

  _1p_kill mise hook-env
  _1p_kill op daemon

  pgrep -x 1password > /dev/null ||
    systemctl --user start app-1password@autostart.service
  1password > /dev/null 2>&1 &!

  echo "1Password relaunched — unlock it, then cd back into the repo"
}
