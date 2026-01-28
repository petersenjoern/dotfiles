# Terminal
## FZF (and aliases)
find . -name "*.py" | ff

# Neovim Hotkeys
## Harpoon
C-e             - overview of harpoon files
C-h             - switch to file 1
C-b             - switch to file 2
C-n             - switch to file 3
C-m             - switch to file 4
<leader> C-h    - Add file to position 1

## Navigation
C-p and C-pf    - find files
<leader>pv      - go to directory
<leader>ps      - grep for word as file content

  Control keys:
  ┌───────┬──────────────────────┐
  │  Key  │        Action        │
  ├───────┼──────────────────────┤
  │ <C-b> │ Harpoon select 2     │
  ├───────┼──────────────────────┤
  │ <C-d> │ Scroll down + center │
  ├───────┼──────────────────────┤
  │ <C-e> │ Harpoon quick menu   │
  ├───────┼──────────────────────┤
  │ <C-f> │ Tmux sessionizer     │
  ├───────┼──────────────────────┤
  │ <C-h> │ Harpoon select 1     │
  ├───────┼──────────────────────┤
  │ <C-j> │ Quickfix prev        │
  ├───────┼──────────────────────┤
  │ <C-k> │ Quickfix next        │
  ├───────┼──────────────────────┤
  │ <C-m> │ Harpoon select 4     │
  ├───────┼──────────────────────┤
  │ <C-n> │ Harpoon select 3     │
  ├───────┼──────────────────────┤
  │ <C-p> │ Telescope git files  │
  ├───────┼──────────────────────┤
  │ <C-u> │ Scroll up + center   │
  └───────┴──────────────────────┘
  Leader keys:
  ┌──────────────────┬────────────────────────────────────┐
  │       Key        │               Action               │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>a/A      │ Harpoon add/prepend                │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>ca       │ Cellular automaton                 │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>d        │ Delete to black hole               │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>e*       │ Go error handling (ea, ee, ef, el) │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>f        │ Format                             │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>fe       │ Reveal file in tree (new)          │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>gs       │ Telescope git status               │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>j/k      │ Location list nav                  │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>p        │ Paste without yank                 │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>pf       │ Telescope find files               │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>ps       │ Telescope grep                     │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>pv       │ Netrw explorer                     │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>pws/pWs  │ Telescope word search              │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>tf       │ Plenary test                       │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>u        │ Undotree                           │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>v*       │ LSP (vca, vd, vrn, vrr, vws)       │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>x        │ chmod +x                           │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>y/Y      │ Yank to clipboard                  │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader>zig      │ LSP restart                        │
  ├──────────────────┼────────────────────────────────────┤
  │ <leader><leader> │ Source file                        │
  └──────────────────┴────────────────────────────────────┘

  ┌────────┬─────────┬─────────────────────────────────┐
  │  Key   │  Mode   │             Action              │
  ├────────┼─────────┼─────────────────────────────────┤
  │ s      │ n, x, o │ Jump to any location            │
  ├────────┼─────────┼─────────────────────────────────┤
  │ S      │ n, x, o │ Select treesitter nodes         │
  ├────────┼─────────┼─────────────────────────────────┤
  │ r      │ o       │ Remote flash (operator-pending) │
  ├────────┼─────────┼─────────────────────────────────┤
  │ R      │ o, x    │ Treesitter search               │
  ├────────┼─────────┼─────────────────────────────────┤
  │ Ctrl+s │ c       │ Toggle flash in search mode     │
  └────────┴─────────┴─────────────────────────────────┘

  ┌─────────┬────────────────────────────────────────┐
  │ Keybind │                 Action                 │
  ├─────────┼────────────────────────────────────────┤
  │ ]d      │ Go to next diagnostic                  │
  ├─────────┼────────────────────────────────────────┤
  │ [d      │ Go to previous diagnostic              │
  ├─────────┼────────────────────────────────────────┤
  │ ]e      │ Go to next error (skips warnings)      │
  ├─────────┼────────────────────────────────────────┤
  │ [e      │ Go to previous error                   │
  ├─────────┼────────────────────────────────────────┤
  │ ]w      │ Go to next warning                     │
  ├─────────┼────────────────────────────────────────┤
  │ [w      │ Go to previous warning                 │
  ├─────────┼────────────────────────────────────────┤
  │ <C-W>d  │ Open diagnostic float for current line │
  └─────────┴────────────────────────────────────────┘

  Your config has these quickfix keymaps in remap.lua:56-62:
  - <C-k> - next quickfix item
  - <C-j> - previous quickfix item


  ┌────────────┬───────────────────────────┐
  │    Key     │          Action           │
  ├────────────┼───────────────────────────┤
  │ <leader>tn │ Run nearest test          │
  ├────────────┼───────────────────────────┤
  │ <leader>tf │ Run tests in file         │
  ├────────────┼───────────────────────────┤
  │ <leader>ts │ Run test suite            │
  ├────────────┼───────────────────────────┤
  │ <leader>tl │ Re-run last test          │
  ├────────────┼───────────────────────────┤
  │ <leader>tv │ Visit last test file      │
  └────────────┴───────────────────────────┘

  - <leader>pt - Find tests with Telescope
  - <CR> - Jump to test
  - <C-r> - Run test

- <leader>q - to close the quickfix window


## Other
:cq             - exit with error code
:Ex!            - discard changes

# LLM CLI
## Generic
cat <<EOF | llm <enter>
write your content
across lines, and end with:
EOF


## CMD
llm cmd <your nlp query to command>

or with chat:

<your nlp query to command> and press `ALT + \`
sed -i '' 's/search/replace/g' file.go # Now do it for all go files in the project

## Template
llm -t find 'find all go files that contain the phrase hello world'
llm -t repomix 'include the file under claude/hooks/*.py'

## Logs
llm logs -c (current conversation)
llm logs list -n 10 -s
llm logs --cid <id for specific conversation> (llm logs --cid 01k971ymkrcy9hkbvg130v7vsv --json | jq | nvim)
llm logs -x (extract first fenced code block)
llm logs --xl (extract last fenced code block)

# TIG (https://jonas.github.io/tig/doc/manual.html)
tig <tab> (to easily select directories/filenames/commits)
tig <filename>
tig <directory>
tig blame <filename>
tig log <dir/file/rev/path>
tig --after="May 5th" --before="2006-05-16 15:44"
tig tag-1.0..tag-2.0
tig --since=1.month -n20 -- Documentation/
tig --all --since=1.week -- Makefile

## views
m - Switch to main view.
d - Switch to diff view.
l - Switch to log view.
p - Switch to pager view.
t - Switch to (directory) tree view.
f - Switch to (file) blob view.
g - Switch to grep view.
b - Switch to blame view.
r - Switch to refs view.
y - Switch to stash view.
h - Switch to help view
s - Switch to status view
c - Switch to stage view

# Ripgrep
## Often used
rg "hello" --type py
rg -l "hello" --type py | ffm


# Repomix
## Often used
repomix --include "**/*.py" --ignore "**/*.log,tmp/" --style xml --no-file-summary --remove-empty-lines --stdout

# OBS: piping into repomix --stdin is causing formatting issues in my tmux session.
# instead of -stdin, find the files with the rg expression, and then write a new repomix --include expression
rg --files-with-matches "hello" | repomix --stdin
rg -l "hello" --type py | ffm | repomix --stdin

# Symbex
## Often used
symbex -x ./.venv -d . -s --docs --typed
symbex -x ./.venv -d . "*dang* --docs --typed
symbex -x ./.venv -d . "*dang*" --docs --typed  >> repomix-output.xml
symbex -x ./.venv -d . --docs --class -s
symbex -x ./.venv -f ./hello.py --async -s --docs --typed
