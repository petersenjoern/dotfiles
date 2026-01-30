if [[ "$ENABLE_CORRECTION" == "true" ]]; then
  CORRECT_IGNORE="[_|.]*|dev|test|staging|prod|feature-jp|cdk|kubectl|nvim|tmux|ap"
  alias cp='nocorrect cp'
  alias man='nocorrect man'
  alias mkdir='nocorrect mkdir'
  alias mv='nocorrect mv'
  alias sudo='nocorrect sudo'
  alias su='nocorrect su'
  alias cdk='nocorrect cdk'
  setopt correct_all
fi

