#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

"""Write Claude Code session state to /tmp/claude-status/ for tmux integration.

Called by Claude Code hooks with a state argument:
    status_hook.py working    # PreToolUse
    status_hook.py attention  # permission_prompt / elicitation_dialog
    status_hook.py idle       # Stop / idle_prompt
"""

import os
import sys
from pathlib import Path

VALID_STATES = {"working", "attention", "idle"}
STATUS_DIR = Path("/tmp/claude-status")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(0)

    state = sys.argv[1]
    if state not in VALID_STATES:
        sys.exit(0)

    pane = os.environ.get("TMUX_PANE")
    if not pane:
        sys.exit(0)

    STATUS_DIR.mkdir(exist_ok=True)
    (STATUS_DIR / pane).write_text(state)


if __name__ == "__main__":
    main()
