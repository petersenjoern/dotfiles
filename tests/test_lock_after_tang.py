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
import signal
import subprocess
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path

import pytest

GUARD_SCRIPT = (
    Path(__file__).resolve().parents[1] / "env/.local/scripts/lock-after-tang"
)
BUDGET_S = 1
# Runs meant to fail spend their whole budget, so give them less of it.
FAILING_BUDGET_S = 0.5
SESSION_ID = "c7"
STUBBED = [
    "omarchy-shell",
    "loginctl",
    "logger",
    "omarchy-notification-send",
    "dbus-monitor",
]

# Each stub logs its call, then answers from the first rule whose key is in its
# arguments. A rule's replies come in turn, and the last one repeats.
# Unmatched calls succeed silently. A reply can kill every process of the run,
# as logind does to everything in a session it terminates.
STUB_SOURCE = """#!{python} -IS
import json, os, signal, sys, time

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
        if reply.get("kill_session"):
            os.killpg(0, signal.SIGTERM)
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
PASSWORD_LOGIN = {"loginctl": {"Service": [{"stdout": "sddm\n"}]}}
RECORD = "state/lock-after-tang.failure"
RECORDED_REASON = "the shell refused to lock"


def sent(calls: list[dict], cmd: str, words: str = "") -> list[list[str]]:
    return [
        c["args"] for c in calls if c["cmd"] == cmd and words in " ".join(c["args"])
    ]


def logged(calls: list[dict], priority: str) -> list[list[str]]:
    return sent(calls, "logger", f"-p user.{priority}")


def failure_record(tmp_path: Path) -> list[str]:
    """Splits the failure record into its time, entry point and reason."""
    return (tmp_path / RECORD).read_text().rstrip("\n").split("\t")


def seed_failure_record(tmp_path: Path) -> Path:
    """Leaves the record of a lock that failed in an earlier session."""
    record = tmp_path / RECORD
    record.parent.mkdir()
    record.write_text(f"2026-11-18T08:00:03+01:00\tlogin\t{RECORDED_REASON}\n")
    return record


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

    def run(
        replies: dict, *, tang: bool = True, budget: float = BUDGET_S
    ) -> tuple[int, list[dict]]:
        (tmp_path / "replies.json").write_text(json.dumps(AUTOLOGIN | replies))
        env = os.environ | {
            "PATH": f"{stubs}:{os.environ['PATH']}",
            "STUB_HOME": str(tmp_path),
            "XDG_STATE_HOME": str(tmp_path / "state"),
            "XDG_SESSION_ID": SESSION_ID,
            "LOCK_AFTER_TANG_MARKER": str(marker if tang else tmp_path / "absent"),
            "LOCK_AFTER_TANG_BUDGET": str(budget),
            "LOCK_AFTER_TANG_POLL": "0.01",
        }
        # Its own process group stands in for the logind session.
        proc = subprocess.run(
            [GUARD_SCRIPT], check=False, env=env, timeout=10, start_new_session=True
        )
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
    unlocked = status_reply(lastEvent="unlocked")
    code, calls = run_guard(
        {
            "omarchy-shell": {
                "lock status": [IDLE, LOCKING, unlocked],
                "lock lock": [LOCK_OK],
            }
        }
    )

    assert code == 0
    assert len(sent(calls, "omarchy-shell", "lock lock")) == 1
    assert logged(calls, "info")


def test_a_lock_dropped_by_a_restarted_shell_is_requested_again(run_guard):
    restarted = status_reply(lastEvent="init")
    _, calls = run_guard(
        {
            "omarchy-shell": {
                "lock status": [IDLE, LOCKING, restarted],
                "lock lock": [LOCK_OK],
            }
        }
    )

    assert len(sent(calls, "omarchy-shell", "lock lock")) > 1


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


def test_a_lock_that_never_comes_ends_the_session(run_guard, tmp_path):
    code, calls = run_guard(
        {"omarchy-shell": {"lock status": [IDLE, LOCKING], "lock lock": [LOCK_OK]}},
        budget=FAILING_BUDGET_S,
    )

    time_, entry, reason = failure_record(tmp_path)
    age = datetime.now().astimezone() - datetime.fromisoformat(time_)
    assert age < timedelta(minutes=1)
    assert entry == "login"
    assert reason == (
        f"the shell did not secure the session within {FAILING_BUDGET_S} s"
    )
    [message] = [args[-1] for args in logged(calls, "err")]
    assert reason in message
    terminated = sent(calls, "loginctl", "terminate-session")
    assert terminated == [["terminate-session", SESSION_ID]]
    # It would land on the screen of whoever is at the keyboard.
    assert sent(calls, "omarchy-notification-send") == []
    assert code != 0


def test_the_failure_is_on_record_before_the_session_ends(run_guard, tmp_path):
    code, calls = run_guard(
        {
            "omarchy-shell": {"lock status": [IDLE, LOCKING], "lock lock": [LOCK_OK]},
            "loginctl": AUTOLOGIN["loginctl"]
            | {"terminate-session": [{"kill_session": True}]},
        },
        budget=FAILING_BUDGET_S,
    )

    assert code == -signal.SIGTERM
    assert failure_record(tmp_path)[2]
    steps = [
        c["cmd"]
        for c in calls
        if c["cmd"] == "logger" or "terminate-session" in c["args"]
    ]
    assert steps == ["logger", "loginctl"]


@pytest.mark.parametrize(
    ("shell", "reason"),
    [
        (
            {"lock status": [IDLE], "lock lock": [{"stdout": "missing-pam\n"}]},
            "no lock screen is configured",
        ),
        (
            {"lock status": [status_reply(passwordPam=False)], "lock lock": [LOCK_OK]},
            "no lock screen is configured",
        ),
        (
            {"lock status": [IDLE], "lock lock": [{"stdout": "failed\n"}]},
            "the shell refused to lock",
        ),
        (
            {"lock status": [SHELL_DOWN], "lock lock": [SHELL_DOWN]},
            "the shell did not answer",
        ),
    ],
    ids=["missing-pam", "no-password-pam", "failed", "no-answer"],
)
def test_the_failure_names_what_went_wrong(run_guard, tmp_path, shell, reason):
    _, calls = run_guard({"omarchy-shell": shell}, budget=FAILING_BUDGET_S)

    assert failure_record(tmp_path)[2] == reason
    assert reason in logged(calls, "err")[0][-1]


def test_a_recorded_failure_is_shown_once_at_the_next_session(run_guard, tmp_path):
    record = seed_failure_record(tmp_path)
    _, calls = run_guard(
        {"omarchy-shell": {"lock status": [IDLE, SECURE], "lock lock": [LOCK_OK]}}
    )

    [notice] = sent(calls, "omarchy-notification-send")
    assert "-u critical" in " ".join(notice)
    assert any(RECORDED_REASON in arg for arg in notice)
    assert not record.exists()


def test_a_shell_that_never_answers_keeps_the_record(run_guard, tmp_path):
    record = seed_failure_record(tmp_path)
    _, calls = run_guard(
        PASSWORD_LOGIN | {"omarchy-shell": {"lock status": [SHELL_DOWN]}},
        budget=FAILING_BUDGET_S,
    )

    assert sent(calls, "omarchy-notification-send") == []
    assert record.exists()


def test_a_notification_that_fails_keeps_the_record(run_guard, tmp_path):
    record = seed_failure_record(tmp_path)
    run_guard(
        PASSWORD_LOGIN
        | {
            "omarchy-shell": {"lock status": [IDLE]},
            "omarchy-notification-send": {"": [{"exit": 1}]},
        }
    )

    assert record.exists()


def test_without_a_recorded_failure_nothing_is_shown(run_guard):
    _, calls = run_guard(PASSWORD_LOGIN | {"omarchy-shell": {"lock status": [IDLE]}})

    assert sent(calls, "omarchy-notification-send") == []


def test_the_lock_is_requested_before_the_failure_is_shown(run_guard, tmp_path):
    seed_failure_record(tmp_path)
    _, calls = run_guard(
        {"omarchy-shell": {"lock status": [IDLE, SECURE], "lock lock": [LOCK_OK]}}
    )

    steps = [
        c["cmd"]
        for c in calls
        if c["cmd"] == "omarchy-notification-send" or "lock lock" in " ".join(c["args"])
    ]
    assert steps == ["omarchy-shell", "omarchy-notification-send"]


@pytest.mark.parametrize(
    ("session", "tang"),
    [(PASSWORD_LOGIN, True), (AUTOLOGIN, False)],
    ids=["password-login", "no-tang-marker"],
)
def test_a_session_the_login_guard_skips_still_shows_the_failure(
    run_guard, tmp_path, session, tang
):
    # The failed autologin sent the owner to the greeter, and the shell is still starting.
    record = seed_failure_record(tmp_path)
    _, calls = run_guard(
        session | {"omarchy-shell": {"lock status": [SHELL_DOWN, SHELL_DOWN, IDLE]}},
        tang=tang,
    )

    assert sent(calls, "omarchy-shell", "lock lock") == []
    assert len(sent(calls, "omarchy-notification-send")) == 1
    assert not record.exists()


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q"]))
