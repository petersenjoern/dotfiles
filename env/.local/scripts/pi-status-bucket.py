#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

"""Write pi agent state for a tmux pane.

Usage:
    uv run --script pi-status-bucket.py working
    uv run --script pi-status-bucket.py attention
    uv run --script pi-status-bucket.py idle

Reads $TMUX_PANE and writes the state to /tmp/pi-agent-status/<pane_id>.
Used by the pi status-bus extension.
"""

import os
import sys
from pathlib import Path

VALID_STATES = {"working", "attention", "idle"}
STATUS_DIR = Path("/tmp/pi-agent-status")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(0)

    state = sys.argv[1]
    if state not in VALID_STATES:
        sys.exit(0)

    pane = os.environ.get("TMUX_PANE")
    if not pane:
        sys.exit(0)

    STATUS_DIR.mkdir(mode=0o700, exist_ok=True)
    (STATUS_DIR / pane).write_text(state)


if __name__ == "__main__":
    main()
