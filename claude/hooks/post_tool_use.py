#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# ///

"""PostToolUse hook — check a file right after Claude edits it.

Runs the project's own gate when there is one (`make lint`), and otherwise
falls back to pyright for Python files. Exit code 2 feeds the output back to
Claude, so it sees the breakage it just caused and fixes it in the same turn
instead of at commit time.

Nothing runs when the project has no `lint` target and pyright is not
installed, or when the edited file lives outside the project directory.
"""

import json
import shutil
import subprocess
import sys
from pathlib import Path

CHECKED_SUFFIXES = {".py", ".ts", ".tsx"}
FILE_TOOLS = {"Edit", "Write", "MultiEdit"}
MAX_LINES = 15
TIMEOUT_SECONDS = 50

# `lint:` or `lint: deps`, but not `.PHONY: lint` or `pylint:`
LINT_TARGET = "\nlint:"


def edited_file(input_data: dict) -> Path | None:
    """The in-project source file this call edited, if it edited one."""
    if input_data.get("tool_name") not in FILE_TOOLS:
        return None

    raw_path = (input_data.get("tool_input") or {}).get("file_path")
    if not isinstance(raw_path, str) or not raw_path:
        return None

    path = Path(raw_path)
    if path.suffix not in CHECKED_SUFFIXES or not path.is_file():
        return None
    if not path.resolve().is_relative_to(Path.cwd().resolve()):
        return None
    return path


def run(command: list[str]) -> tuple[int, str]:
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        timeout=TIMEOUT_SECONDS,
    )
    return result.returncode, result.stdout + result.stderr


def make_lint() -> tuple[int, str] | None:
    """Run `make lint` when the project defines that target."""
    makefile = Path.cwd() / "Makefile"
    if not makefile.is_file():
        return None
    if LINT_TARGET not in "\n" + makefile.read_text():
        return None
    return run(["make", "lint"])


def pyright(path: Path) -> tuple[int, str] | None:
    """Type-check a single Python file, reporting errors only."""
    if path.suffix != ".py" or not shutil.which("pyright"):
        return None

    _, output = run(["pyright", "--outputjson", str(path)])
    try:
        diagnostics = json.loads(output).get("generalDiagnostics", [])
    except json.JSONDecodeError:
        return None  # pyright itself failed; not the edit's problem

    errors = [d for d in diagnostics if d.get("severity") == "error"]
    if not errors:
        return 0, ""

    lines = []
    for diagnostic in errors:
        line = diagnostic.get("range", {}).get("start", {}).get("line", 0) + 1
        lines.append(f"{path}:{line}: {diagnostic.get('message', '').splitlines()[0]}")
    return 1, "\n".join(lines)


def main() -> None:
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    try:
        path = edited_file(input_data)
        if path is None:
            sys.exit(0)

        result = make_lint() or pyright(path)
    except (OSError, subprocess.SubprocessError) as exc:
        print(f"post_tool_use: check skipped: {exc!r}", file=sys.stderr)
        sys.exit(0)

    if result is None:
        sys.exit(0)

    returncode, output = result
    if returncode == 0:
        sys.exit(0)

    reported = output.strip().splitlines()[:MAX_LINES]
    print("\n".join(reported), file=sys.stderr)
    if len(output.strip().splitlines()) > MAX_LINES:
        print("... (output truncated)", file=sys.stderr)
    sys.exit(2)  # Exit code 2 surfaces stderr to Claude


if __name__ == "__main__":
    main()
