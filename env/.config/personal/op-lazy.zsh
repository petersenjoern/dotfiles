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
    export "$var=$(op read "$ref")"
  fi
}

op_load() {
  op_env ANTHROPIC_API_KEY "op://Personal/anthropic-api/credential"
  op_env AWS_BEARER_TOKEN_BEDROCK "op://Work/aws-bedrock/credential"
}
