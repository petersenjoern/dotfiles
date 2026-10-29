# tmux-map: a glanceable map of Claude sessions, worktrees, branches and PRs

## Problem

Each tmux window runs Claude Code in a git worktree. Claude switches branches
inside a worktree, creates further worktrees from inside one (EnterWorktree →
`.claude/worktrees/<name>`), and opens PRs that later merge. A session's
scrollback is often buried under PR-comment polling output. Nothing answers
"which window has which session, doing what, on which worktree, branch and
PR" without visiting every window.

Priorities: (1) a glanceable map, (2) finding a specific task and jumping to
it, (3) resuming context on one session. Cleanup actions are out of scope.

## What exists today

- `env/.local/scripts/tmux-worktree`: `cc-wt-N` windows over
  `.worktrees/wt-N`, a manifest, and `overview` on `prefix+t`. It only sees
  `cc-wt-*` windows and their checked-out branch.
- `claude/hooks/status_hook.py`: writes `working|attention|idle` to
  `/tmp/claude-status/$TMUX_PANE`. `tmux-cc-indicator` (status-bar badge) and
  `claude-next` read it. Neither may break.
- `env/.local/scripts/tmux-focus <pane>`: focuses the Ghostty window, then
  switches client, window and pane.

## Overview

Two changes:

1. **`status_hook.py` records per-pane session data** as
   `/tmp/claude-status/<pane>.json`, alongside the existing plain state file.
2. **A new stateless script `env/.local/scripts/tmux-map`** collects tmux, git,
   hook and `gh` data on every open, renders a tree, and pipes it to fzf in a
   popup on `prefix+t`.

There is no daemon and no database. Merged or closed things fall away
because the map only shows what is currently true.

## Hook: `claude/hooks/status_hook.py`

The hook reads the hook JSON from stdin. It still writes the plain state file
exactly as before. It exits silently when `TMUX_PANE` is unset.

### Wiring (`claude/settings.json`)

| Event | Arg | New? |
|---|---|---|
| PreToolUse | `working` | existing |
| Notification `permission_prompt` / `elicitation_dialog` | `attention` | existing |
| Notification `idle_prompt` | `idle` | existing |
| Stop | `idle` | existing; the payload is now read |
| UserPromptSubmit | `prompt` | new; leaves the plain state file untouched |
| SessionStart | `start` | new; leaves the plain state file untouched |
| SessionEnd | inline `rm` | existing; also removes `<pane>.json` |

### `/tmp/claude-status/<pane>.json`

```json
{
  "session_id": "1c443f7e-…",
  "pane_pid": 12345,
  "transcript_path": "/home/joern/.claude/projects/…/1c443f7e-….jsonl",
  "session_title": "Trialcore turbopuffer filter opportunities",
  "last_prompt": "…",
  "last_prompt_at": "2026-10-28T12:52:09Z",
  "cwds": ["/home/joern/repos/work/amass/.worktrees/wt-3", "…/.claude/worktrees/exp-x"],
  "branches": ["feat/issn-attr", "fix/issn-null"],
  "crons": 1,
  "updated_at": "2026-10-28T12:52:09Z"
}
```

### Update rules

- **New session.** A `session_id` different from the stored one starts a fresh
  record. This covers `/clear` and recycles.
- **Subagents.** A payload carrying `agent_id` only sets the plain state.
  Nothing in the JSON changes.
- **On `UserPromptSubmit` and `Stop`:**
  - Append the payload `cwd` to `cwds` and `git branch --show-current` (run in
    that cwd) to `branches`. Both are de-duplicated and keep their order.
  - Take `session_title` from the payload when present.
- **Meaningful prompts.** On `UserPromptSubmit`, the prompt counts only when
  all three hold:
  - `source` is absent or `user`, and the prompt doesn't start with `<`, so
    loop, schedule, poll and system ticks don't count. `source` is still
    rolling out, so an injected `<task-notification>` can arrive without it.
  - It is at least 20 characters long. That alone filters bare confirmations
    such as `yes`, `go` and `yes to all`. A list of exact confirmation words
    would add nothing.

  A meaningful prompt becomes `last_prompt`. `last_prompt_at` updates on
  every prompt.
- **On `Stop`:** `crons = len(session_crons or [])`.
- **On `SessionStart`:** record `session_id`, `transcript_path` and
  `session_title`.
- **`pane_pid`** comes from `tmux display -p -t $TMUX_PANE '#{pane_pid}'`.
- **Pane border.** Whenever the label changes, run
  `tmux set -p -t $TMUX_PANE @cc_title "<label>"`. The label is the title,
  else the first 60 characters of the last prompt. When a new session has no
  label yet, unset the option instead. `SessionEnd` unsets it too, so a
  respawned pane never shows the old title.
- **Writes.** Write to a temp file and `os.replace` it into place, so the map
  never reads a partial file.

## Map: `env/.local/scripts/tmux-map`

A stdlib-only Python 3 script in the same style as `tmux-worktree`. fzf is the
UI.

### Collection (on open and on `ctrl-r`)

1. **Panes.** `tmux list-panes -a -F` gives `session`, `window_index`,
   `window_name`, `window_active`, `pane_id`, `pane_pid`,
   `pane_current_command`, `pane_current_path` and `pane_active`.
2. **Claude state.** A pane whose `pane_current_command == "claude"` is a
   Claude pane. Its `<pane>.json` is used only when the JSON's `pane_pid`
   matches. Otherwise the row shows `(untitled)` with the state from the
   plain file. This covers sessions started before the hook was deployed.
   Delete JSON files whose pane no longer exists.
   Without a hook record, the transcript comes from Claude Code's own
   `~/.claude/sessions/<pid>.json`. That file carries `"tmux":
   "<session>:@<window>.%<pane>"` and `sessionId`, and the transcript is
   `~/.claude/projects/*/<sessionId>.jsonl`. Only live pids count.
3. **Repos.** Resolve every `pane_current_path` and every hook `cwd` to its
   main repo root (`git rev-parse --path-format=absolute --git-common-dir` →
   parent). For each repo, read `git worktree list --porcelain`.
4. **Titles and PR links.** Read the transcript backwards over its last
   ~256 KB:
   - The title is the last `custom-title` if any, else the last `ai-title`,
     else the hook's `session_title`, else `last_prompt`.
   - Collect `prNumber` from `pr-link` entries.
5. **PRs.** Run `gh pr list --author @me --state all --limit 100 --json
   number,title,state,reviewDecision,headRefName,url` per repo, all repos in
   parallel with a 5 s timeout each. Cache the result per repo for 60 s under
   `$XDG_CACHE_HOME/tmux-map/<repo-hash>.json`.
   - In parallel, a second call (`--state open --limit 30 --json
     number,statusCheckRollup`) gets CI checks for open PRs only. Asking for
     checks on all 100 PRs took 8.5 s, against 1 s for the open ones. Each
     PR's checks collapse to `fail` (any failure, error, cancellation,
     timeout or action required), `pending` (anything not yet passed) or
     `pass` (success, neutral or skipped).
   - If the call fails, use the cache whatever its age and mark the repo
     header `(PRs stale)`.
   - With no cache at all, the PR column shows `?`.

### Tree

```
amass ─────────────────────────────────────────────────────────────────
 3 cc-wt-2   ⚠ 🔁 Address review on ISSN attribute        #812 review
               └ wt-2                 feat/issn-attr       #812 review
               └ .claude/worktrees/x  fix/issn-null        #815 merged ↺
 4 cc-wt-3   ⏳    Add retry to ingest client               —
               └ wt-3                 wt/3
   loose       ·  feat/old-thing                           #790 open
dotfiles ──────────────────────────────────────────────────────────────
 1 main      ✓    tmux map brainstorm                      —
               └ .                    feat/tmux-map
```

**Window rows**
- A window appears when it has a Claude pane, or when its active pane (or
  else its first pane in a repo) is rooted in a **non-main** worktree.
  Windows without Claude in the main checkout (nvim, services, notes) are
  hidden as noise.
- The window column shows the index, plus `session:` when the tmux session
  name differs from the repo name.
- A window with no Claude shows only its worktree and branch.
- A window with several Claude panes gets one row per pane.

**Claude row**
- Shows the state icon (`⚠ ⏳ ✓`), then 🔁 when `crons > 0`, then the time
  since the last state change (`now`, `4m`, `2h`, `1d`, from the state file's
  mtime), then the title, then the PR of the live branch.
- The PR column is the CI symbol (`✓` pass, `✗` fail, `●` running; open PRs
  only) followed by `#n` and the review state.

**Children of a Claude row**
- One row per worktree in `cwds`, showing that worktree's checked-out branch.
- One row per branch in `branches` that still exists locally and isn't
  already shown.
- Each branch shows its PR. The PR comes from matching `headRefName`, or from
  the session's `pr-link` numbers for branches that no longer match one.
- Merged or closed PRs are dimmed and marked `↺`. History rows (branches and
  `pr-link` PRs, not worktrees) with a finished PR are left out of the list,
  because long sessions cycle through a dozen. The preview lists them.

**Colors** use ANSI 0–15 only, so they follow the Omarchy theme:
- **Claude state:** red `⚠` for needs you (the title turns bold red too),
  yellow `⏳` for working, green `✓` for done.
- **PR:** yellow "needs review", green "approved", red "changes requested",
  plain "open", dim "merged/closed ↺". CI checks: green `✓`, red `✗`,
  yellow `●`.
- **Age:** dim.
- **Window number and name:** tinted with the window's `@wt_color`, which
  matches its tmux tab.

**Loose branches**
- Listed under the repo header: local branches with an **open** PR that are
  not checked out in any worktree and not already shown under a session.

**Worktrees with no pane**
- Hidden by default. `ctrl-a` toggles a dimmed "no window" section per repo.
  There are no actions on these rows.

### fzf

**Line format.** Each line is `target \t visible \t blob \t url`:
- `target`: a pane id to jump to, or `wt:<path>` / `br:<repo>:<branch>`
  for preview-only rows, or empty for headers
- `blob`: session title, all branches, `#number title` of every PR the
  session touched (including merged ones hidden from the list), worktree
  paths. Prompts were dropped: they mention other worktrees and PRs in
  passing, so "wt-9" also hit any session that talked about wt-9. All rows of
  a session share its blob, so a hit shows the session with its children.

fzf runs with `--exact` (substring matching; a `'` prefix makes one term
fuzzy). Fuzzy matching hit almost every row, because a few characters in
order turn up somewhere in a long blob.
- `url`: the row's PR, empty when it has none. It isn't displayed; `{4}`
  reads it.

fzf only searches fields it displays, so `--with-nth=2,3` displays the
visible text padded with 400 spaces, which pushes the blob off-screen.
`--no-hscroll --ellipsis=` stop a match in the blob from scrolling it into
view. `--accept-nth=1` returns the target, and `{1}` in the preview command
refers to the original first field.

**Keys**
- `Enter` → `tmux-focus <pane>`. A Claude row, or any of its children, jumps
  to the Claude pane. A window row jumps to that window's active pane.
- `ctrl-o` → `execute-silent(tmux-map --open {4})+abort`. This shows the
  row's PR in the Omarchy GitHub web app:
  - A Chrome `--app` window keeps the class of the URL it was launched with
    (`chrome-github.com__…`), while its title follows the page
    ("… · Pull Request #1444 · owner/repo").
  - If a GitHub app window's title already names this PR, focus that window.
  - Otherwise run `omarchy-launch-webapp <url>`. `hypr/windows.lua` sends the
    new window to workspace 3 silently. Wait up to 5 s for a GitHub app
    window whose address wasn't there before; its title still reads
    "loading" at first. Then focus it, falling back to workspace 3.
  - Dispatch uses Hyprland's Lua form: `hyprctl dispatch 'hl.dsp.focus({
    window = "address:…" })'`, or `{ workspace = "3" }`. Plain `focuswindow`
    and `workspace` are rejected without a visible error.
  - Chrome can't point an existing app window at a new URL, so each PR not
    already open gets its own window.
  - Without `hyprctl`, `xdg-open` the URL.
- `ctrl-r` → `reload(tmux-map --lines)`, keeping the current mode.
- `ctrl-a` → toggles pane-less worktrees. The mode lives in the prompt
  (`> ` vs `all> `), which `transform` reads from `$FZF_PROMPT`.

**Preview** (`tmux-map --preview <pane>`) sits below the list
(`down,45%`) so the list gets the full popup width. It never calls `gh`; it
reads the PR cache regardless of age. It is built from the transcript, not
the screen. Capturing the pane mostly showed Claude's own UI: the prompt
box, the status line, update notices. It shows:
- the title, in bold
- one summary line: worktree · branch · state in words with its time
  (the state file's mtime) · `🔁 polling`
- the live PR's state, CI checks in words ("✓ checks pass"), title and URL
- **You · time**: your last typed prompt (`turnOrigin == "human"`; tool
  results, loop ticks and notifications are skipped; slash commands are
  shown as `/name args`)
- **Claude · time**: Claude's last text reply. Both come from the last 2 MB
  of the transcript.
- **Earlier in this session**: every other branch or PR the session touched,
  with PR state and title, newest PR number first. The list's child rows use
  the same order: worktrees first, then history by PR number descending,
  branches without a PR last.

**Binding.** In `tmux/.tmux.conf`:
`bind t display-popup -E -w 90% -h 85% "$HOME/.local/scripts/tmux-map"`.
This replaces the `tmux-worktree overview` binding. The subcommand stays in
`tmux-worktree`.

### Pane border

`tmux/.tmux.conf` sets a `pane-border-format` that shows `#{@cc_title}` when
it is set and falls back to the current default otherwise.

### Status bar

`status-right` starts with `#(tmux-cc-indicator --all)`, which counts the
panes running `claude` per state across every tmux session: `⚠1 ⏳2 ✓5`, in
red, yellow and green, with zero counts left out. `status-right-length` is
80 so the branch and clock still fit.

## Edge cases

- **Pane ids reused after a tmux restart.** The `pane_pid` check rejects the
  old JSON, and collection step 2 deletes it.
- **Detached worktrees.** The branch column shows `(detached)`.
- **Missing or rotated transcript.** Fall back to the hook's `session_title`,
  then to `last_prompt`, then to `(untitled)`.
- **`gh` not installed or not logged in.** Handled the same as a `gh`
  failure.
- **A pane whose cwd is outside any git repo** is not shown, unless it runs
  Claude, in which case it goes under a `(no repo)` header.

## Out of scope

- Claude sessions outside tmux (no `TMUX_PANE`).
- Other hosts: state lives in each host's `/tmp`.
- Cleanup actions: no recycling or removing worktrees from the map. Opening
  a PR (`ctrl-o`) is the only action.
- History of closed sessions.

## Verification

- Label selection, tree building and stale filtering are pure functions over
  the collected data.
- `tmux-map --dump` prints the rendered tree to stdout without fzf. Check it
  against the live tmux server, including a window whose Claude has entered a
  `.claude/worktrees/*` worktree and a session running a `/loop`.
- Confirm that `tmux-cc-indicator` and `claude-next` behave unchanged.
- There is no test suite, matching `tmux-worktree`.

## Files touched

- `claude/hooks/status_hook.py`
- `claude/settings.json`
- `env/.local/scripts/tmux-map` (new)
- `env/.local/scripts/tmux-cc-indicator`: `--all` counts
- `tmux/.tmux.conf`: `prefix+t` binding, `pane-border-format`, `status-right`
- `cheatsheet.md`: `prefix+t` entry

`dev-env-omarchy` already copies all of these into place.
