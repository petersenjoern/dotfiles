## Environment

Tools (node, bun, uv, python, npx, etc.) are managed by
[mise](https://mise.jdx.dev). mise is activated in the shell profile, so these
tools are already on PATH in the Bash tool. Run them directly (e.g. `npm run
test`, `uv run pytest`) — do NOT prepend `export PATH="$HOME/.local/share/mise/shims:$PATH"`
to commands. Prepending it turns every command into a compound `export ... && cmd`
that no longer matches permission allow-rules or auto-mode, causing needless prompts.

AWS commands I run myself go through aws-vault shell aliases, one per
environment: `vp` (prod), `vd` (development and feature envs like
`feature-jp`), `vt` (test). When writing a run line for me, prefix the command
with the alias, e.g. `ENVIRONMENT=prod SINCE=2026-10-08 vp uv run python
scratch/probe_issns_attribute.py`. Never write `<prod AWS exec>` or another
placeholder.

## Git

- Pre-commit hooks run ruff format on Python files. If the hook reformats a
  file, the commit fails. Re-stage the reformatted files and commit again.
- Commits are GPG-signed via 1Password. If signing fails with "failed to fill
  whole buffer", retry the commit.

## Workflow Rules

- Never create PRs unless explicitly asked.
- When I open a PR through you, or tell you which PR number the branch belongs
  to, start a 10-minute poll in the same turn (`/loop 10m`, or a
  CronCreate/ScheduleWakeup loop). On each tick, check `gh pr view <n> --json
  state` and fetch comments posted since the last check: review comments,
  issue comments, and reviews (`gh api repos/{owner}/{repo}/pulls/<n>/comments`,
  `.../issues/<n>/comments`, `.../pulls/<n>/reviews`). Address or report each
  new comment. Stop the loop once the PR is merged or closed.
- When the request is straightforward, skip brainstorming/option-listing and go
directly to implementation. Only brainstorm when explicitly asked or when the
problem is genuinely ambiguous.

## Code Changes

- Prefer minimal, targeted fixes over large refactors. Choose the smallest
change that solves the problem. Do not refactor surrounding code unless asked.
- After making multi-file changes, re-read all modified files to verify
consistency. Check that all references to renamed/removed functions, fields, or
types are updated across the entire codebase.

## Comments

- Write the shortest comment that carries the information. One line is the
  default; more than that needs a reason.
- Explain why, not what. Delete any comment that restates the code.
- No section banners, no docstring that repeats the signature, no "Note that
  ...", no closing summary line.
- When a change adds or rewrites more than a couple of comments or docstrings,
  run the `no-ai-slop` skill over that comment text and apply its edits — the
  same slop patterns show up in comments as in prose.

## Python Style

- Use modern type syntax: lowercase `dict`, `list`, `tuple` instead of `typing.Dict`, `typing.List`, `typing.Tuple`.
- Use `X | None` instead of `Optional[X]`.
- Default mutable arguments should use field defaults or None with factory patterns, never bare mutable defaults.
- Default to functional programming with pure functions. Only use classes when you need:
  - State that persists across method calls
  - Complex state initialization or lifecycle management
  - Clear object identity and encapsulation boundaries
- Use `moto` whenever you write unittests that include AWS services. `from moto import mock_aws`

## Next.js Learning Mode

When editing or creating frontend files (*.tsx, *.ts, *.jsx):
- After implementing, briefly explain which Next.js concepts are involved and
  whether this runs on server or client.
- If you considered a more idiomatic approach but chose simplicity, mention it.
