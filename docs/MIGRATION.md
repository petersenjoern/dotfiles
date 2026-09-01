# Machine Migration & Reinstall Guide

How to back up state that lives **outside** this repo, and restore it on a
fresh machine.

## Philosophy

Everything in this repo is reproducible: run `./dev-env-omarchy` (or
`./dev-env`) on the new machine and configs land in the right places. This
guide covers what is **not** version-controlled — credentials, encryption keys,
sync state, and personal files referenced by the repo.

Three categories:

1. **Sync via account login** — restored by signing back into a service. No file backup needed.
2. **Files to back up** — must be captured before the wipe.
3. **Regenerated automatically** — skip; tools rebuild on first run.

---

## 1. Sync via account login

These restore by logging back into the service on the new machine.

| Service | Restores | New-machine command |
|---------|----------|---------------------|
| 1Password | SSH keys (used by SSH agent), op CLI secrets, anything fetched via `op_env` / `op_load` | Sign in to 1Password app + `eval $(op signin)` |
| Atuin | Encrypted shell history | `atuin login -u <username>` (also needs the encryption key — see §2) |
| GitHub | gh CLI auth | `gh auth login` |
| Google Drive (rclone) | OAuth tokens for the TODO.md backup timer | `rclone config` (re-OAuth as `gdrive` remote) — alternative to restoring `~/.config/rclone/rclone.conf` from tarball |

---

## 2. Files to back up before wipe

Gitignored, referenced by the repo, or app credentials not managed here.

### Identity & signing

```
~/.gitconfig-personal           # git user/email/signingkey
~/.gitconfig-work               # if applicable
~/.ssh/allowed_signers          # SSH commit-signing trust list
```

### Local config not in repo

```
<dotfiles>/dotfiles.local.conf  # holds AWS_VAULT_FILE_PASSPHRASE among other locals
<repos>/personal/TODO.md        # referenced by backup-todo timer + tmux-sessionizer
~/.claude/                      # Claude Code state — auto-memory, project transcripts, plans,
                                # tasks, todos, .credentials.json. Skip cache/telemetry/logs
                                # (see backup command excludes).
```

### Credentials & encrypted stores

```
~/.local/share/atuin/key        # 72 bytes — without it, synced history is unrecoverable
~/.awsvault/                    # aws-vault file backend keys (encrypted)
~/.aws/config                   # profiles + regions only (no secrets — kept for convenience)
~/.config/rclone/rclone.conf    # Google Drive OAuth tokens for backup-todo timer
```

> **Do not back up `~/.aws/credentials`.** AWS credentials are managed by aws-vault. The plaintext credentials file should be empty or absent.

> **Do not back up `~/.docker/config.json` or `~/.config/gh/hosts.yml`.** These hold tokens that are cleaner to regenerate via `docker login` / `gh auth login` than to migrate.

### Backup command

```bash
# Exclude paths are matched against archive members (leading "/" stripped),
# so they use the home/<user>/... form.
USER_HOME_REL="home/$USER"

tar czf ~/predeploy-backup.tgz \
  --exclude="${USER_HOME_REL}/.claude/cache" \
  --exclude="${USER_HOME_REL}/.claude/telemetry" \
  --exclude="${USER_HOME_REL}/.claude/statsig" \
  --exclude="${USER_HOME_REL}/.claude/debug" \
  --exclude="${USER_HOME_REL}/.claude/paste-cache" \
  --exclude="${USER_HOME_REL}/.claude/plugins" \
  --exclude="${USER_HOME_REL}/.claude/shell-snapshots" \
  --exclude="${USER_HOME_REL}/.claude/file-history" \
  --exclude="${USER_HOME_REL}/.claude/backups" \
  --exclude="${USER_HOME_REL}/.claude/sessions" \
  --exclude="${USER_HOME_REL}/.claude/session-env" \
  --exclude="${USER_HOME_REL}/.claude/usage-data" \
  --exclude="${USER_HOME_REL}/.claude/bash-command-log.txt" \
  --exclude="${USER_HOME_REL}/.claude/history.jsonl" \
  --exclude="${USER_HOME_REL}/.claude/stats-cache.json" \
  --exclude="${USER_HOME_REL}/.claude/mcp-needs-auth-cache.json" \
  --exclude="${USER_HOME_REL}/.claude/.last-cleanup" \
  ~/.gitconfig-personal \
  ~/.gitconfig-work \
  ~/.ssh/allowed_signers \
  ~/.local/share/atuin/key \
  ~/.awsvault \
  ~/.aws/config \
  ~/.config/rclone/rclone.conf \
  ~/.claude \
  <dotfiles>/dotfiles.local.conf \
  <repos>/personal/TODO.md
```

Excluded `.claude` subdirs are caches, telemetry, plugin downloads, debug logs,
shell-snapshots, file-history, ephemeral session state, and `bash-command-log.txt`
(which can contain commands run with secrets in argv). All regenerate or are
not worth migrating. Expected size: ~75 MB.

Stash the tarball off the machine: 1Password Document item, encrypted external
drive, or encrypted cloud bucket.

For paranoia, also print and save the atuin key to 1Password:

```bash
atuin key  # copy the output into a 1Password Secure Note
```

---

## 3. Regenerated automatically (skip)

| Path | Rebuilt by |
|------|-----------|
| `~/.tmux/plugins/` | TPM (`prefix + I`) |
| `~/.local/share/nvim/` | Lazy.nvim on first launch |
| `~/.oh-my-zsh/` | omz installer |
| Mise tools | `mise install` (reads `mise.toml` from repo) |

> If you want bit-for-bit nvim plugin reproducibility, commit `lazy-lock.json`
> to the repo before wiping. Without it, plugins float to whatever's at HEAD on
> each repo at install time.

---

## Atuin: shell history sync

Atuin keeps shell history encrypted in cloud sync. Migration relies on three things:

1. The cloud account (`atuin register` / `atuin login`)
2. The encryption key (`~/.local/share/atuin/key`) — without this, the synced data is undecryptable
3. The `history_filter` in `atuin/config.toml` (in this repo) to keep secrets out going forward

### Pre-wipe: scrub sensitive entries

The `history_filter` in `atuin/config.toml` only filters **new** commands. Anything recorded before a filter was added is already in the cloud DB. Clean it before reinstall.

`atuin search` does substring matching (modes: `prefix`, `full-text`, `fuzzy`, `skim`). Use `full-text` for explicit substrings.

```bash
# Dry-run: review matches
atuin search --search-mode full-text --cmd-only '<pattern>' | less

# Delete matches
atuin search --search-mode full-text --delete '<pattern>'

# Push deletions to cloud
atuin sync
```

#### Recommended scrub patterns

**High-signal (rarely false positive):**

| Pattern | Catches |
|---------|---------|
| `AKIA` | AWS access keys |
| `ASIA` | AWS temporary access keys |
| `ghp_` `gho_` `ghs_` `ghu_` `github_pat_` | GitHub tokens |
| `sk-ant-` | Anthropic API keys |
| `sk-proj-` | OpenAI project keys |
| `xoxb-` `xoxp-` `xoxa-` `xoxr-` | Slack tokens |
| `glpat-` | GitLab personal access tokens |
| `hf_` | HuggingFace tokens |
| `eyJ` | JWT prefix (catches almost any signed-token leak) |

**Broader patterns — review before deleting:**

| Pattern | Catches |
|---------|---------|
| `TOKEN=` | Bare assignment (your `^export` filter misses these) |
| `PGPASSWORD=` `MYSQL_PWD=` | DB password env vars |
| `--token=` `--api-key=` `--password=` `--secret=` | Inline secret flags |
| `Authorization:` | Bearer / basic auth headers |
| `curl -u ` `curl --user ` | curl basic auth |
| `gh auth login --with-token` | GitHub token piped via stdin |
| `docker login -p` `docker login --password` | Inline docker registry password |
| `npm config set` | npm `_authToken` writes |

**Mistypes (passwords typed at the prompt):**

```bash
# Surfaces "command not found" entries — passwords typed by accident often appear here
atuin search --exit 127 --search-mode full-text '' | less
```

### Pre-wipe: ensure final sync

```bash
atuin sync
```

### New machine: restore

After running `./dev-env-omarchy` (which deploys `atuin/config.toml`):

```bash
# Install atuin (Arch / Omarchy)
pacman -S atuin

# Sign in — prompts for password and encryption key
atuin login -u <username>

# Force a full pull
atuin sync -f
```

If you'd rather skip the login flow and you backed up the full atuin data dir in your tarball, restore it before first run instead:

```bash
mkdir -p ~/.local/share/atuin
tar xzf ~/predeploy-backup.tgz -C ~/.local/share .local/share/atuin
atuin sync
```

---

## New machine setup order

1. Install OS, base tools (`git`, `zsh`, `vim`, `atuin`, `aws-vault`, `mise`, `rclone`, `1password`, `1password-cli`)
2. Sign in to 1Password — restores SSH agent
3. Clone this dotfiles repo, set `DEV_ENV` env var
4. Restore tarball:
   ```bash
   tar xzf ~/predeploy-backup.tgz -C /
   ```
   (verify paths first; `tar tzf ~/predeploy-backup.tgz | head` to inspect)
5. `cp dotfiles.local.conf.example dotfiles.local.conf` if not in tarball, fill in
6. Run `./dev-env-omarchy` (or `./dev-env` for non-Arch).
   **Omarchy 4 note:** `dev-env-omarchy` deploys Lua Hyprland configs and the
   `~/.local/state/omarchy/current/` theme paths — it assumes Omarchy >= 4.0.0
   "Quattro" and must not be run on an Omarchy 3.x machine.
7. `source ~/.zshrc`
8. `atuin login -u <username>` + `atuin sync -f`
9. `gh auth login`, `docker login` (etc.) for services where you skipped credential backup
10. `mise install` to rebuild toolchains
11. Open nvim → Lazy installs plugins
12. Open tmux → `prefix + I` to install plugins via TPM
13. Enable the TODO.md backup timer:
    ```bash
    # Verify rclone config restored from tarball (or run `rclone config` to re-OAuth)
    rclone listremotes  # should show "gdrive:"

    systemctl --user daemon-reload
    systemctl --user enable --now backup-todo.timer
    systemctl --user list-timers backup-todo.timer
    ```

---

## What to rotate vs. restore

A reinstall is a free excuse to rotate static long-lived credentials. Consider rotating instead of migrating:

- AWS access keys (rotate in IAM, then re-add via `aws-vault add`)
- GitHub PATs (regenerate in GitHub settings)

Keys you cannot easily rotate (SSH keys not managed by 1Password) must be migrated.
