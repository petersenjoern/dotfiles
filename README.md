# My Awesome Dotfiles

A collection of configuration files for my personal development environment.

## About These Dotfiles

These dotfiles represent my curated setup for native/WSL Ubuntu (see my repo devenv) and Archlinux (using Omarchy).
I am primarily working in web development and AI. Preferred tools for CLIs/scripts are bash, python and go.
My goal is to maintain a consistent and productive environment across my machine with minimal friction and mouse usage. I believe in keyboard first, sensible defaults and powerful CLI tools.


## Features

* **Zsh**: My primary shell
* **VSCode**: mostly for feature richness and debugging tooling, however, operated and customized with (vim) hotkeys to reduce mouse usage.
* **Vim/Neovim**: customised (mostly inspired by theprimeagen), usage for short edits, quick script creation etc.
* **Git**: personalized for easier commits and branch management
* **Tmux**: for session (one per project) and window management
* **Mise**: global and project specific tool, env and task automation setup
* **Mouseless**: configuration to navigating mouseless for example on windows due to lack of good tiling manager
* **LLM**: CLI for adhoc usage of LLMs in the terminal.
* **Custom scripts**:
    * `dev-env`: Script to purge old and copy new dotfiles into respective directories
* **Other tools**: `fzf`, `bat`, `fd`, `ripgrep`


## Setup

1. Ensure you have a **backup** of all your configurations.
2. Clone the repository
```bash
git clone https://github.com/petersenjoern/dotfiles.git [path-to-folder]/dotfiles
export DEV_ENV="[path-to-folder]/dotfiles"
cd $DEV_ENV
```
3. Install Zsh and vim (find offical installation or look at my repo devenv)
3. Run setup script (OBS: read `dev-env` or `dev-env-omarchy` for understanding how the dotfiles will be setup. Edit as required.
```bash
./dev-env
source ~/.zshrc
```

From now you can edit your configurations under `[path-to-folder/dotfiles]` and subsequently execute `dev-env` and `source ~/.zshrc` on any path.


