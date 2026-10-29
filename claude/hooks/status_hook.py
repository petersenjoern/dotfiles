#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# ///

"""Write Claude Code session state to /tmp/claude-status/ for tmux integration.

Called by Claude Code hooks with a state argument:
    status_hook.py working    # PreToolUse
    status_hook.py attention  # permission_prompt / elicitation_dialog
    status_hook.py idle       # Stop / idle_prompt
    status_hook.py prompt     # UserPromptSubmit (record only)
    status_hook.py start      # SessionStart (record only)

<pane> holds the bare state for tmux-cc-indicator and claude-next.
<pane>.json holds what tmux-map shows: title, prompts, cwds, branches, crons.
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

VALID_STATES = {"working", "attention", "idle"}
RECORD_ARGS = {"idle", "prompt", "start"}
RECORD_EVENTS = {"UserPromptSubmit", "Stop", "SessionStart"}
STATUS_DIR = Path("/tmp/claude-status")
# Shorter prompts are confirmations ("yes", "go ahead") that make useless labels.
MIN_PROMPT_LEN = 20
MAX_PROMPT_LEN = 500


def run(*cmd: str, cwd: str | None = None) -> str:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=2)
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return r.stdout.strip() if r.returncode == 0 else ""


def append_unique(items: list[str], item: str) -> None:
    if item and item not in items:
        items.append(item)


def label(record: dict) -> str:
    return record.get("session_title") or record.get("last_prompt", "")[:60]


def update_record(pane: str, payload: dict) -> None:
    event = payload.get("hook_event_name")
    if event not in RECORD_EVENTS:
        return

    path = STATUS_DIR / f"{pane}.json"
    try:
        record = json.loads(path.read_text())
    except (OSError, ValueError):
        record = {}
    old_label = label(record)
    session_id = payload.get("session_id")
    # A new session id (fresh start, /clear, recycle) starts a fresh record.
    if record.get("session_id") != session_id:
        record = {"session_id": session_id, "cwds": [], "branches": []}

    pane_pid = run("tmux", "display", "-p", "-t", pane, "#{pane_pid}")
    if pane_pid.isdigit():
        record["pane_pid"] = int(pane_pid)
    if payload.get("transcript_path"):
        record["transcript_path"] = payload["transcript_path"]
    if payload.get("session_title"):
        record["session_title"] = payload["session_title"]

    cwd = payload.get("cwd", "")
    if event != "SessionStart" and cwd:
        append_unique(record["cwds"], cwd)
        append_unique(
            record["branches"], run("git", "branch", "--show-current", cwd=cwd)
        )

    if event == "UserPromptSubmit":
        record["last_prompt_at"] = datetime.now(timezone.utc).isoformat()
        prompt = " ".join(payload.get("prompt", "").split())[:MAX_PROMPT_LEN]
        # Loop, schedule and system ticks must not overwrite what you asked for.
        # `source` is still rolling out, so injected <task-notification> and
        # similar tags also arrive without it.
        typed = payload.get("source") in (None, "user") and not prompt.startswith("<")
        if typed and len(prompt) >= MIN_PROMPT_LEN:
            record["last_prompt"] = prompt
    elif event == "Stop":
        record["crons"] = len(payload.get("session_crons") or [])

    # Replace, never rewrite in place: tmux-map may be reading it.
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(record, indent=2))
    os.replace(tmp, path)

    new_label = label(record)
    if new_label != old_label:
        if new_label:
            run("tmux", "set", "-p", "-t", pane, "@cc_title", new_label)
        else:
            run("tmux", "set", "-p", "-u", "-t", pane, "@cc_title")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(0)

    arg = sys.argv[1]
    if arg not in VALID_STATES | RECORD_ARGS:
        sys.exit(0)

    pane = os.environ.get("TMUX_PANE")
    if not pane:
        sys.exit(0)

    # /tmp is shared, so keep the directory to this user.
    STATUS_DIR.mkdir(mode=0o700, exist_ok=True)
    if arg in VALID_STATES:
        (STATUS_DIR / pane).write_text(arg)

    # PreToolUse fires constantly; only the record events need the payload.
    if arg not in RECORD_ARGS:
        return
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return
    # Subagents share the pane; their cwd and prompts belong to the parent's work.
    if payload.get("agent_id"):
        return
    update_record(pane, payload)


if __name__ == "__main__":
    main()
