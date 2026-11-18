#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pytest"]
# ///

"""Behaviour tests for the lock-after-tang guard: `uv run tests/test_lock_after_tang.py`.

The guard runs as a subprocess with stub commands first on PATH, so no test
needs root, a Tang box or a running Omarchy shell.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

GUARD_SCRIPT = (
    Path(__file__).resolve().parents[1] / "env/.local/scripts/lock-after-tang"
)
STUBBED = [
    "omarchy-shell",
    "loginctl",
    "logger",
    "omarchy-notification-send",
    "dbus-monitor",
]

# Each stub logs its call, then answers from the first rule whose key is in its
# arguments. A rule's replies come in turn, and the last one repeats.
# Unmatched calls succeed silently.
STUB_SOURCE = """#!{python} -IS
import json, os, sys, time

name = os.path.basename(sys.argv[0])
args = sys.argv[1:]
home = os.environ["STUB_HOME"]
with open(os.path.join(home, "calls.jsonl"), "a") as log:
    log.write(json.dumps({{"cmd": name, "args": args}}) + "\\n")
with open(os.path.join(home, "replies.json")) as f:
    rules = json.load(f).get(name, {{}})
line = " ".join(args)
for i, (key, replies) in enumerate(rules.items()):
    if key in line:
        counter = os.path.join(home, f"{{name}}.{{i}}.count")
        n = int(open(counter).read()) if os.path.exists(counter) else 0
        with open(counter, "w") as f:
            f.write(str(n + 1))
        reply = replies[min(n, len(replies) - 1)]
        time.sleep(reply.get("delay", 0))
        sys.stdout.write(reply.get("stdout", ""))
        sys.exit(reply.get("exit", 0))
"""


def status_reply(**fields) -> dict:
    base = {
        "requested": False,
        "pending": False,
        "secure": False,
        "realScreens": 1,
        "passwordPam": True,
    }
    return {"stdout": json.dumps(base | fields)}


SHELL_DOWN = {"stdout": "", "exit": 1}
IDLE = status_reply()
LOCKING = status_reply(requested=True)
SECURE = status_reply(requested=True, secure=True)
LOCK_OK = {"stdout": "ok"}


def sent(calls: list[dict], cmd: str, words: str = "") -> list[list[str]]:
    return [
        c["args"] for c in calls if c["cmd"] == cmd and words in " ".join(c["args"])
    ]


@pytest.fixture
def run_guard(tmp_path):
    stubs = tmp_path / "stubs"
    stubs.mkdir()
    for name in STUBBED:
        stub = stubs / name
        stub.write_text(STUB_SOURCE.format(python=sys.executable))
        stub.chmod(0o755)
    marker = tmp_path / "tang-unlock.conf"
    marker.touch()

    def run(replies: dict, *, tang: bool = True) -> tuple[int, list[dict]]:
        (tmp_path / "replies.json").write_text(json.dumps(replies))
        env = os.environ | {
            "PATH": f"{stubs}:{os.environ['PATH']}",
            "STUB_HOME": str(tmp_path),
            "XDG_STATE_HOME": str(tmp_path / "state"),
            "LOCK_AFTER_TANG_MARKER": str(marker if tang else tmp_path / "absent"),
            "LOCK_AFTER_TANG_BUDGET": "1",
            "LOCK_AFTER_TANG_POLL": "0.01",
        }
        proc = subprocess.run([GUARD_SCRIPT], check=False, env=env, timeout=10)
        log = tmp_path / "calls.jsonl"
        lines = log.read_text().splitlines() if log.exists() else []
        return proc.returncode, [json.loads(line) for line in lines]

    return run


def test_a_slow_shell_start_still_gets_locked(run_guard):
    code, calls = run_guard(
        {
            "omarchy-shell": {
                "lock status": [SHELL_DOWN, SHELL_DOWN, IDLE, LOCKING, SECURE],
                "lock lock": [LOCK_OK],
            }
        }
    )

    assert code == 0
    assert sent(calls, "omarchy-shell", "lock lock")


def test_without_the_tang_marker_the_guard_does_nothing(run_guard):
    code, calls = run_guard({"omarchy-shell": {"lock status": [IDLE]}}, tang=False)

    assert code == 0
    assert sent(calls, "omarchy-shell") == []


def test_no_new_lock_request_while_the_shell_is_locking(run_guard):
    _, calls = run_guard(
        {
            "omarchy-shell": {
                "lock status": [IDLE, LOCKING],
                "lock lock": [LOCK_OK],
            }
        }
    )

    assert len(sent(calls, "omarchy-shell", "lock status")) > 2
    assert len(sent(calls, "omarchy-shell", "lock lock")) == 1


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q"]))
