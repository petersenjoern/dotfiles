# Terminal
## FZF (and aliases)
find . -name "*.py" | ff

# Git (aliases)
`g` is aliased to `git` (see `env/.config/personal/aliases`); the rest live in `git/.gitconfig`.
## Commit
`g acm "msg"`   - stage everything (`add -A`) + `commit -m` in one step
`g cm "msg"`    - commit -m
`g cam "msg"`   - commit -am (tracked changes only)
`g ca`          - commit --amend
`g aca`         - add -A + commit --amend (edit message)
`g acan`        - add -A + commit --amend --no-edit (keep message)
## Conventional commits (auto-prepend the type)
`g feat "msg"`  - commit "feat: msg"
`g fix "msg"`   - commit "fix: msg"
`g chore "msg"` - commit "chore: msg"
`g ref "msg"`   - commit "refactor: msg"

## aws-vault wrappers
`v` is aliased to `aws-vault`; `vp`/`vd` wrap `exec ... --`.
`vp <cmd>`      - aws-vault exec prod -- <cmd>   (e.g. `vp make invoke-task-step ...`)
`vd <cmd>`      - aws-vault exec dev  -- <cmd>

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

## Bracket motions `[` / `]`
Mnemonic: `]` always goes forward, `[` always goes backward. Uppercase = the
*end* of the node instead of its start. All of these take a count (`3]m`), and
the treesitter ones work in operator-pending mode too (`d]m`, `y[c`).

### Learn these by heart
  ┌───────────┬──────────────────────────────────────────────────────────────┐
  │    Key    │                            Action                            │
  ├───────────┼──────────────────────────────────────────────────────────────┤
  │ [{ / ]}   │ Jump to the *unmatched* enclosing brace. Repeat to climb out  │
  │           │ of nested blocks. `[(` / `])` for parens. Works as an         │
  │           │ operator target: `d[{`, `v]}`.                                │
  ├───────────┼──────────────────────────────────────────────────────────────┤
  │ ]m / [m   │ Next / prev function start (treesitter). Best way to skim a   │
  │           │ file's structure. `]M` / `[M` for function *end*.             │
  ├───────────┼──────────────────────────────────────────────────────────────┤
  │ ]c / [c   │ Next / prev git hunk. Falls through to class start when the   │
  │           │ buffer has no changes. `]C` / `[C` for class end.             │
  ├───────────┼──────────────────────────────────────────────────────────────┤
  │ ]d / [d   │ Next / prev diagnostic (opens the float on arrival).          │
  │           │ `<C-W>d` shows the diagnostic under the cursor without moving.│
  ├───────────┼──────────────────────────────────────────────────────────────┤
  │ ]q / [q   │ Next / prev quickfix entry (nvim default). `]Q` / `[Q` for    │
  │           │ first / last. Anything that fills quickfix — Spectre, :grep,  │
  │           │ vim-test failures, LSP references — becomes bracket-navigable.│
  ├───────────┼──────────────────────────────────────────────────────────────┤
  │ ]p / [p   │ Paste re-indented to match the current line. Not a motion,    │
  │           │ but the bracket command you will use most.                    │
  ├───────────┼──────────────────────────────────────────────────────────────┤
  │ ]s / [s   │ Next / prev misspelled word (needs `:set spell`). Pair with   │
  │           │ `z=` to correct and `zg` to add to the dictionary.            │
  └───────────┴──────────────────────────────────────────────────────────────┘

### Treesitter moves (nvim-treesitter-textobjects)
  ┌─────────┬────────────────────┬──────────────────────────────────────────┐
  │   Key   │       Target       │                 Textobject               │
  ├─────────┼────────────────────┼──────────────────────────────────────────┤
  │ ]m / [m │ function start     │ `af` / `if` to select                    │
  ├─────────┼────────────────────┼──────────────────────────────────────────┤
  │ ]M / [M │ function end       │                                          │
  ├─────────┼────────────────────┼──────────────────────────────────────────┤
  │ ]c / [c │ class start        │ `ac` / `ic` to select                    │
  ├─────────┼────────────────────┼──────────────────────────────────────────┤
  │ ]C / [C │ class end          │                                          │
  ├─────────┼────────────────────┼──────────────────────────────────────────┤
  │ ]a / [a │ parameter          │ `aa` / `ia` to select                    │
  ├─────────┼────────────────────┼──────────────────────────────────────────┤
  │ ]i / [i │ conditional (if)   │                                          │
  ├─────────┼────────────────────┼──────────────────────────────────────────┤
  │ ]o / [o │ loop               │                                          │
  ├─────────┼────────────────────┼──────────────────────────────────────────┤
  │ ]/ / [/ │ comment            │                                          │
  └─────────┴────────────────────┴──────────────────────────────────────────┘

### Other built-ins worth knowing
`]z` / `[z`     - end / start of the current open fold
`` ]` `` / `` [` ``  - next / prev lowercase mark (`]'` / `['` for linewise)
`]]` / `[[`     - next / prev section; fallback for files with no TS parser
`[I`            - list every line containing the word under the cursor
                  (`[<C-i>` jumps to the first one) — grep without leaving the buffer
`]b` / `[b`     - next / prev buffer (nvim default; also `]B` / `[B` for first / last)
`]l` / `[l`     - location list (nvim default; you also have `<leader>k` / `<leader>j`)
`]<Space>`      - insert a blank line below without leaving normal mode (`[<Space>` above)


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


Debugging in vim:
  1. Open neovim in your pipeline project directory
  2. Press <leader>dc to start debugging
  3. Select a "Pipeline: ..." config from the list
  4. For configs with args, you'll be prompted to enter the date

  Press <leader> and wait 300ms to see a popup with all your keybindings. I added group labels for your
  existing mappings:
  ┌───────────┬───────────────┐
  │  Prefix   │     Group     │
  ├───────────┼───────────────┤
  │ <leader>d │ debug         │
  ├───────────┼───────────────┤
  │ <leader>t │ test          │
  ├───────────┼───────────────┤
  │ <leader>p │ project/files │
  ├───────────┼───────────────┤
  │ <leader>g │ git           │
  ├───────────┼───────────────┤
  │ <leader>v │ vim           │
  ├───────────┼───────────────┤
  │ <leader>s │ search        │
  └───────────┴───────────────┘
  Comment.nvim
  ┌─────────────┬────────────────────────────────────────────────────────┐
  │ Keybinding  │                         Action                         │
  ├─────────────┼────────────────────────────────────────────────────────┤
  │ gcc         │ Toggle line comment                                    │
  ├─────────────┼────────────────────────────────────────────────────────┤
  │ gbc         │ Toggle block comment                                   │
  ├─────────────┼────────────────────────────────────────────────────────┤
  │ gc + motion │ Comment with motion (e.g., gc3j comments 3 lines down) │
  ├─────────────┼────────────────────────────────────────────────────────┤
  │ gb + motion │ Block comment with motion                              │
  ├─────────────┼────────────────────────────────────────────────────────┤
  │ gcO         │ Add comment line above                                 │
  ├─────────────┼────────────────────────────────────────────────────────┤
  │ gco         │ Add comment line below                                 │
  ├─────────────┼────────────────────────────────────────────────────────┤
  │ gcA         │ Add comment at end of line                             │
  └─────────────┴────────────────────────────────────────────────────────┘
  In visual mode, just select and press gc or gb.

  nvim-autopairs

  - Auto-closes (), [], {}, "", ''
  - Treesitter-aware (won't add pairs inside strings)
  - Integrates with nvim-cmp: selecting a function adds () automatically
  - <M-e> (Alt+e) for fast-wrap - wrap existing text with pairs

  ┌─────┬─────────────────────────┬──────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │  #  │         Keymap          │         What it does         │                                                       Why it matters                                                       │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 1   │ <leader>vca             │ Code action                  │ Fixes imports, extracts functions, auto-implements interfaces — the single most powerful LSP shortcut.                     │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 2   │ <leader>vrn             │ Rename symbol                │ Project-wide safe rename. Beats find-and-replace every time.                                                               │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 3   │ <leader>ps              │ Grep search (Telescope)      │ Find any string across the entire project instantly. Your main "where is this used?" tool.                                 │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 4   │ <leader>db + <leader>dc │ Breakpoint + Continue        │ Actual debugging instead of print statements. Even occasional use saves huge time on complex bugs.                         │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 5   │ <leader>sr              │ Spectre search & replace     │ Multi-file search-and-replace with preview. Essential for refactors too small for LSP rename.                              │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 6   │ af / if                 │ Select around/inner function │ Combine with d, y, c — delete/yank/change entire functions. Composable power.                                              │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 7   │ <leader>o               │ Toggle test/impl file        │ One keystroke to flip between code and its test. Removes the biggest friction point in TDD flow.                           │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 8   │ <leader>vrr             │ Show references              │ "Who calls this?" — essential before refactoring or deleting anything. The complement to gd.                               │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 9   │ <leader>vd              │ Open diagnostic float        │ See the full error message inline without leaving your cursor. Faster than scanning the statusline or jumping to quickfix. │
  ├─────┼─────────────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 10  │ ]m / [m                 │ Next/prev function start     │ Jump function-by-function through a file. Best way to skim a file's structure without a sidebar.                           │
  └─────┴─────────────────────────┴──────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘



## nvim-tree
R                   - refresh tree (cursor must be in nvim-tree buffer)
:NvimTreeRefresh    - refresh tree from anywhere
<leader>fe          - reveal current file in tree (also forces a refresh)
C-S-e               - toggle tree

Note: `.worktrees` is in `filesystem_watchers.ignore_dirs`, so files
created there won't auto-appear — use `R` to refresh.

### Resizing (cursor must be in the tree)
C-Right             - widen by 5 columns
C-Left              - narrow by 5 columns
<leader>r           - reset to the configured width (35)
:NvimTreeResize 50  - jump to an absolute width (`+10` / `-10` also work)

Default width and `preserve_window_proportions` live in
`env/.config/nvim/lua/config/lazy/nvim-tree.lua`. Without the latter, opening a
file equalizes every window and the tree snaps back to its old size.

### Creating files and folders
`a` prompts with the containing directory pre-filled — the folder under the
cursor, or the parent of the file under the cursor. What you type after it
decides what gets made:
  foo.lua             - a file
  foo/                - a folder (trailing slash is the whole difference)
  a/b/c.lua           - c.lua plus every missing folder on the way
The new node is revealed in the tree afterwards, so you land on it.

### Other file ops
r / e / u           - rename (full name / basename only / full path)
d / D               - delete / trash
c / x / p           - copy / cut / paste into the folder under the cursor
y / Y / gy          - yank filename / relative path / absolute path
g?                  - full mapping list for the tree buffer

## Other
:cq             - exit with error code
:Ex!            - discard changes

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

## tig from tmux (opens in the current pane's repo)
`prefix + g`    - full tig (commit log) in a `tig-<repo>` window; again from
                  inside it jumps back to the previous window
`prefix + G`    - same, but tig status
`prefix + C-g`  - throwaway tig popup (modal: M-<n> is dead until you quit)

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

# Tmux
Prefix is remapped to `C-a` (see `tmux/.tmux.conf`).

## Pane management
`{`             - swap current pane with previous pane
`}`             - swap current pane with next pane
`q`             - show pane indices (briefly)
`swap-pane -s <src> -t <dst>` - swap arbitrary panes by index (run as `:swap-pane ...`)

## Git worktrees (tmux-worktree)
Each worktree is a `cc-wt-N` tmux window with a 5-pane dev layout
(nvim / claude / shell / BE / FE). Windows are auto-tinted with a stable
palette color (status-bar tab + pane borders) so you can tell them apart at
a glance. Color is stored in `.worktrees/manifest.json` and survives restore.

`prefix + T`    - create a new worktree + window (fzf branch picker, ctrl-n = new branch)
`prefix + t`    - overview of all worktree windows (status, unpushed, recyclable hints)
`prefix + C-t`  - restore tmux windows for worktrees that lost their window
`prefix + X`    - remove a worktree + window (safety checks; `--force`, `--volumes`)
`prefix + C-x`  - recycle: reuse the window for a fresh branch off main (keeps services warm)

`M-1`..`M-9`    - jump straight to window N
`M-,` / `M-.`   - move current window left / right
