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
import time
from pathlib import Path

import pytest

GUARD_SCRIPT = (
    Path(__file__).resolve().parents[1] / "env/.local/scripts/lock-after-tang"
)
BUDGET_S = 1
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
AUTOLOGIN = {"loginctl": {"Service": [{"stdout": "sddm-autologin\n"}]}}


def sent(calls: list[dict], cmd: str, words: str = "") -> list[list[str]]:
    return [
        c["args"] for c in calls if c["cmd"] == cmd and words in " ".join(c["args"])
    ]


def logged(calls: list[dict], priority: str) -> list[list[str]]:
    return sent(calls, "logger", f"-p user.{priority}")


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
        (tmp_path / "replies.json").write_text(json.dumps(AUTOLOGIN | replies))
        env = os.environ | {
            "PATH": f"{stubs}:{os.environ['PATH']}",
            "STUB_HOME": str(tmp_path),
            "XDG_STATE_HOME": str(tmp_path / "state"),
            "LOCK_AFTER_TANG_MARKER": str(marker if tang else tmp_path / "absent"),
            "LOCK_AFTER_TANG_BUDGET": str(BUDGET_S),
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
    assert logged(calls, "info")


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


def test_a_password_login_is_left_alone(run_guard):
    code, calls = run_guard(
        {
            "loginctl": {"Service": [{"stdout": "sddm\n"}]},
            "omarchy-shell": {"lock status": [IDLE], "lock lock": [LOCK_OK]},
        }
    )

    assert code == 0
    assert sent(calls, "omarchy-shell", "lock lock") == []
    assert sent(calls, "logger") == []


def test_a_session_whose_login_type_cant_be_read_gets_locked(run_guard):
    code, calls = run_guard(
        {
            "loginctl": {"Service": [{"stdout": "", "exit": 1}]},
            "omarchy-shell": {"lock status": [IDLE, SECURE], "lock lock": [LOCK_OK]},
        }
    )

    assert code == 0
    assert sent(calls, "omarchy-shell", "lock lock")


def test_a_headless_lock_the_shell_holds_counts_as_locked(run_guard):
    held = status_reply(requested=True, pending=True, realScreens=0)
    code, calls = run_guard(
        {"omarchy-shell": {"lock status": [IDLE, held], "lock lock": [LOCK_OK]}}
    )

    assert code == 0
    assert sent(calls, "loginctl", "terminate-session") == []
    assert logged(calls, "info")


@pytest.mark.parametrize(
    "pending",
    [
        status_reply(requested=True, pending=True, realScreens=1),
        {"stdout": json.dumps({"requested": True, "pending": True})},
    ],
    ids=["screens-attached", "screens-unknown"],
)
def test_a_pending_lock_that_may_have_screens_keeps_the_guard_waiting(
    run_guard, pending
):
    code, calls = run_guard(
        {"omarchy-shell": {"lock status": [IDLE, pending], "lock lock": [LOCK_OK]}}
    )

    assert code != 0
    assert len(sent(calls, "omarchy-shell", "lock status")) > 2
    assert len(sent(calls, "omarchy-shell", "lock lock")) == 1


def test_an_immediate_unlock_stays_unlocked(run_guard):
    # The session was secure and unlocked again between two polls.
    code, calls = run_guard(
        {
            "omarchy-shell": {
                "lock status": [IDLE, LOCKING, IDLE],
                "lock lock": [LOCK_OK],
            }
        }
    )

    assert code == 0
    assert len(sent(calls, "omarchy-shell", "lock lock")) == 1
    assert logged(calls, "info")


def test_status_fields_count_only_when_they_are_true(run_guard):
    stringly = status_reply(requested="true", secure="true")
    code, calls = run_guard(
        {"omarchy-shell": {"lock status": [stringly], "lock lock": [LOCK_OK]}}
    )

    assert code != 0
    assert len(sent(calls, "omarchy-shell", "lock lock")) > 1


def test_a_lock_that_comes_up_on_the_final_read_counts(run_guard):
    # The lock request outlasts the budget, so the next status read is the final one.
    code, calls = run_guard(
        {
            "omarchy-shell": {
                "lock status": [IDLE, SECURE],
                "lock lock": [LOCK_OK | {"delay": 3}],
            }
        }
    )

    assert code == 0
    assert logged(calls, "info")


def test_a_stalled_shell_cant_push_the_guard_past_its_budget(run_guard):
    stall = {"stdout": "", "delay": 5}
    start = time.monotonic()
    run_guard({"omarchy-shell": {"lock status": [stall], "lock lock": [stall]}})

    # The margin covers the final status read and process start-up.
    assert time.monotonic() - start < BUDGET_S + 1


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q"]))
