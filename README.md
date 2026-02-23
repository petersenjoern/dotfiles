# My Awesome Dotfiles

A collection of configuration files for my personal development environment.

## About These Dotfiles

These dotfiles represent my curated setup for native/WSL Ubuntu (see my repo devenv) and Archlinux (using Omarchy).
I am primarily working in web development and AI. Preferred tools for CLIs/scripts are bash, python and go.
My goal is to maintain a consistent and productive environment across my machines with minimal friction and mouse usage. I believe in keyboard first, sensible defaults and powerful CLI tools.


## Features

### Core workflow
* **Zsh**: My primary shell
* **Vim/Neovim**: customised (mostly inspired by theprimeagen), usage for short edits, quick script creation etc.
* **VSCode**: mostly for feature richness and debugging tooling, however, operated and customized with (vim) hotkeys to reduce mouse usage
* **Tmux**: session (one per project) and window management, tmux-sessionizer with git worktree support
* **Git**: personalized for easier commits and branch management
* **Mise**: global and project specific tool, env and task automation setup

### AI tooling
* **Claude Code**: custom agents, slash commands, hooks and settings for AI-assisted development
* **LLM**: CLI for adhoc usage of LLMs in the terminal, with templates for code, refactor, planning, etc.
* **LiteLLM**: proxy configuration for routing LLM requests

### Desktop & window management
* **Hyprland**: tiling compositor bindings and monitor setup (Omarchy)
* **GlazeWM**: tiling window manager for Windows
* **Mouseless**: keyboard-driven navigation on Windows

### Terminal & peripherals
* **Alacritty**: terminal emulator config
* **Ghostty**: terminal emulator config (managed via `env/.config/ghostty/`)
* **Tig**: terminal git UI
* **NuPhy**: custom keyboard layouts for NuPhy Air75

### Scripts & tools
* `dev-env` / `dev-env-omarchy`: Scripts to purge old and copy new dotfiles into respective directories
* `tmux-sessionizer`: project session launcher with git worktree support
* Utility scripts: `timer`, `myip`, `copy-pwd`, `browser-search`
* **Other tools**: `fzf`, `bat`, `fd`, `ripgrep`
* **Cheatsheet**: quick reference for hotkeys and shortcuts (`cheatsheet.md`)


## Setup

1. Ensure you have a **backup** of all your configurations.
2. Clone the repository
```bash
git clone https://github.com/petersenjoern/dotfiles.git [path-to-folder]/dotfiles
export DEV_ENV="[path-to-folder]/dotfiles"
cd $DEV_ENV
```
3. Install Zsh and vim (find offical installation or look at my repo devenv)
4. Run setup script (OBS: read `dev-env` or `dev-env-omarchy` for understanding how the dotfiles will be setup. Edit as required.
```bash
# For generic/WSL environments (use --dry to preview changes)
./dev-env
# For Archlinux (Omarchy) environments (use --dry to preview changes)
./dev-env-omarchy
source ~/.zshrc
```

From now you can edit your configurations under `[path-to-folder/dotfiles]` and subsequently execute the setup script and `source ~/.zshrc` on any path.


