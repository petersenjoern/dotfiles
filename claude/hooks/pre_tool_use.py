#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# ///

"""PreToolUse hook — inspects a tool call before it runs.

Two verdicts are possible:

    deny (exit 2)   the call never runs; stderr is shown to Claude.
    ask  (JSON)     Claude Code raises a permission prompt for the user.

Rules that can only fire on something genuinely destructive deny. Rules that
are heuristic — anything parsing a shell command — ask, so a wrong guess costs
a keystroke instead of blocking work with no way to override.

This is a speed bump, not a sandbox. Command construction that hides the real
verb (`base64 -d | sh`, `python -c "os.system(...)"`, `find -delete`) is not
detected, and is not meant to be.
"""

import json
import re
import sys
import shlex
from pathlib import Path

DENY = "deny"
ASK = "ask"

# Shell separators that end one command and begin the next. Parens and command
# substitution are included so `echo "$(env)"` is seen as its own `env` call.
_SEGMENT_SEPARATORS = re.compile(r"\|\||&&|\$\(|[;|&()`\n]")

# VAR=value prefixes, and wrappers that delegate to the command after them.
_ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
_WRAPPERS = frozenset(
    {"sudo", "doas", "command", "builtin", "nohup", "time", "exec", "xargs"}
)
_ELEVATORS = frozenset({"sudo", "doas"})

# `find ... -exec rm -rf {} \;` hides a second command inside one segment.
_NESTED_COMMAND_FLAGS = ("-exec", "-execdir", "-ok", "-okdir")


def _segments(command: str) -> list[list[str]]:
    """Split a shell command into segments, each tokenised into words."""
    parsed = []
    for raw in _SEGMENT_SEPARATORS.split(command):
        try:
            tokens = shlex.split(raw)
        except ValueError:  # unbalanced quotes from splitting mid-string
            tokens = raw.split()
        if not tokens:
            continue
        parsed.append(tokens)
        for flag in _NESTED_COMMAND_FLAGS:
            if flag in tokens:
                nested = tokens[tokens.index(flag) + 1 :]
                if nested:
                    parsed.append(nested)
    return parsed


def _leading_command(tokens: list[str]) -> tuple[str | None, list[str], bool]:
    """Resolve a segment to (command, args, is_elevated), skipping VAR= and sudo."""
    index = 0
    elevated = False
    while index < len(tokens):
        token = tokens[index]
        if _ASSIGNMENT.match(token):
            index += 1
        elif token in _WRAPPERS:
            elevated = elevated or token in _ELEVATORS
            index += 1
            while index < len(tokens) and tokens[index].startswith("-"):
                index += 1
        else:
            break
    if index >= len(tokens):
        return None, [], elevated
    return tokens[index], tokens[index + 1 :], elevated


# Paths where a delete is never a targeted delete, regardless of flags.
_DANGEROUS_TARGETS = frozenset(
    {
        "/",
        "/*",
        "~",
        "~/",
        "~/*",
        "$HOME",
        "${HOME}",
        ".",
        "./",
        "./*",
        "..",
        "../",
        "../*",
        "*",
    }
)


def is_dangerous_rm_command(command: str) -> bool:
    """
    Detect destructive deletes: recursive rm, rm aimed at root/home/cwd/glob,
    and privileged rm. Only genuine `rm` invocations are inspected, so
    `git rm`, `npm rm` and flags that merely contain an "r" are left alone.
    """
    if re.search(r"\bchmod\s+777\b", command):
        return True
    if re.search(r">\s*/etc/", command):
        return True

    for tokens in _segments(command):
        name, args, elevated = _leading_command(tokens)
        if name != "rm" and not (name or "").endswith("/rm"):
            continue
        if elevated:
            return True

        flags = [arg for arg in args if arg.startswith("-") and arg != "--"]
        targets = [arg for arg in args if not arg.startswith("-")]

        recursive = any(
            flag == "--recursive" or re.fullmatch(r"-[a-zA-Z]*[rR][a-zA-Z]*", flag)
            for flag in flags
        )
        if recursive:
            return True
        if any(
            target.rstrip("/") in _DANGEROUS_TARGETS or target in _DANGEROUS_TARGETS
            for target in targets
        ):
            return True

    return False


# An environment variable, by convention: UPPER_SNAKE_CASE, at least two chars.
# Shell loop and local variables ($f, $c, $total) are lowercase and stay allowed.
_ENV_STYLE_EXPANSION = re.compile(r"\$\{?([A-Z][A-Z0-9_]+)\}?")

# Variables every other shell command touches. Printing them reveals nothing,
# and treating them as secrets makes the hook fire on ordinary work.
_BENIGN_ENV_VARS = frozenset(
    {
        "CLAUDE_PROJECT_DIR",
        "COLUMNS",
        "DEV_ENV",
        "EDITOR",
        "EUID",
        "HOME",
        "HOSTNAME",
        "IFS",
        "LANG",
        "LC_ALL",
        "LINES",
        "LOGNAME",
        "OLDPWD",
        "PAGER",
        "PATH",
        "PS1",
        "PS2",
        "PWD",
        "PYTHONPATH",
        "RANDOM",
        "SHELL",
        "SHLVL",
        "TERM",
        "TMPDIR",
        "TMUX_PANE",
        "UID",
        "USER",
        "VIRTUAL_ENV",
        "VISUAL",
    }
)

# Secret-bearing names in any casing, so $tpuf_api_key is caught too.
_SECRET_EXPANSION = re.compile(
    r"\$\{?[A-Za-z0-9_]*"
    r"(?:SECRET|TOKEN|PASSWORD|PASSWD|CREDENTIAL|API_?KEY|ACCESS_?KEY|PRIVATE_?KEY"
    r"|AUTH|BEARER|SESSION|COOKIE)"
    r"[A-Za-z0-9_]*\}?",
    re.IGNORECASE,
)

# Commands that reveal a value rather than merely using it.
_DISCLOSING = re.compile(
    r"(?:^|[;&|(`]|\s)(?:echo|printf|print|cat|eval|tee|read)\b[^;&|]*"
)

# Unambiguous whole-environment dumps — safe to match anywhere in the command.
_ENV_DUMPS = (
    re.compile(r"\bprintenv\b"),
    re.compile(r"\bcompgen\s+-v\b"),
    re.compile(r"\bdeclare\s+-[px]\b"),
    re.compile(r"\bexport\s+-p\b"),
    re.compile(r"\$\{![A-Za-z_]"),  # ${!VAR} indirect expansion
)


def _is_bare_dump(name: str | None, args: list[str]) -> bool:
    """`env` and `set` dump the environment only when given nothing to do."""
    if name == "env":
        return not [arg for arg in args if not arg.startswith("-")]
    if name == "set":
        return not args  # `set -e`, `set -x` configure the shell, they dump nothing
    return False


def check_env_var_lookup(command: str) -> bool:
    """
    Detect attempts to read out environment variable contents: whole-environment
    dumps (printenv, bare env/set, declare -p) and printing a secret-named or
    otherwise non-obvious environment variable. Ordinary shell variables are not
    environment variables, so `echo "$f"` inside a loop is allowed, and neither
    are the everyday ones, so `cat "$HOME/.config/x"` is allowed too.
    """
    if any(pattern.search(command) for pattern in _ENV_DUMPS):
        return True

    for tokens in _segments(command):
        name, args, _ = _leading_command(tokens)
        if _is_bare_dump(name, args):
            return True

    for match in _DISCLOSING.finditer(command):
        fragment = match.group(0)
        if _SECRET_EXPANSION.search(fragment):
            return True
        if any(
            var not in _BENIGN_ENV_VARS
            for var in _ENV_STYLE_EXPANSION.findall(fragment)
        ):
            return True

    return False


# Files holding real secrets. Templates (.env.sample, .env.example) are fine,
# and so is .env.1password, which holds `op://` references rather than values.
_SENSITIVE_BASENAMES = frozenset({".env", ".env.local", "secrets.sh"})
_FILE_TOOLS = frozenset({"Read", "Edit", "MultiEdit", "Write", "NotebookEdit"})


def _is_sensitive_basename(basename: str) -> bool:
    if basename in _SENSITIVE_BASENAMES:
        return True
    # .env.production.local and friends
    return basename.startswith(".env.") and basename.endswith(".local")


def is_sensitive_file_target(tool_name: str, tool_input: dict) -> bool:
    """Check whether a file tool is pointed straight at a secrets file."""
    if tool_name not in _FILE_TOOLS:
        return False
    file_path = tool_input.get("file_path", "")
    return bool(file_path) and _is_sensitive_basename(file_path.split("/")[-1])


def bash_touches_sensitive_file(command: str) -> bool:
    """
    Check whether any word of a shell command names a secrets file. Token-based
    rather than pattern-based, so `cat .env`, `cp ~/app/.env /tmp` and
    `echo x > .env` are all caught while `.env.sample` is left alone.
    """
    return any(
        _is_sensitive_basename(token.rsplit("/", 1)[-1])
        for tokens in _segments(command)
        for token in tokens
    )


def is_github_write_command(command: str) -> bool:
    """
    Detect outward-facing GitHub write/publish operations that must not run
    without explicit user approval: posting PR/issue comments or reviews,
    creating/merging/closing PRs, pushing commits, and any `gh api` call that
    uses a write HTTP method or field flags (which make gh api default to POST).

    Read-only operations are intentionally NOT matched: gh pr view/list/diff/
    checks, gh api GET (no field flags), git status/log/fetch/diff, etc.
    """
    normalized = " ".join(command.lower().split())

    # git push — include compound forms like `cd repo && git push`
    if re.search(r"(^|[;&|]|\s)git\s+push(\s|$)", normalized):
        return True

    # gh pr / gh issue write subcommands
    if re.search(
        r"(^|[;&|]|\s)gh\s+(pr|issue)\s+"
        r"(comment|create|review|merge|close|reopen|edit|ready|lock|unlock|delete)\b",
        normalized,
    ):
        return True

    # gh release write subcommands
    if re.search(
        r"(^|[;&|]|\s)gh\s+release\s+(create|edit|delete|upload)\b", normalized
    ):
        return True

    # gh api with a write method, or with field/input flags (which switch the
    # default verb from GET to POST). An explicit GET method opts back out.
    if re.search(r"(^|[;&|]|\s)gh\s+api\b", normalized):
        has_write_method = re.search(
            r"(-x|--method)\s+(post|put|patch|delete)", normalized
        )
        explicit_get = re.search(r"(-x|--method)\s+get", normalized)
        # NB: the command is lowercased, so -F (raw field) is matched by -f here.
        has_field_flag = re.search(
            r"(^|\s)(-f|--field|--raw-field|--input)(\s|=)", normalized
        )
        if has_write_method or (has_field_flag and not explicit_get):
            return True

    return False


def evaluate(tool_name: str, tool_input: dict) -> tuple[str, str] | None:
    """Return (action, reason) for a tool call, or None to let it through."""
    if is_sensitive_file_target(tool_name, tool_input):
        return DENY, (
            "reading or writing .env/secrets.sh is prohibited — these hold live "
            "credentials. Use .env.sample for templates."
        )

    if tool_name != "Bash":
        return None

    command = tool_input.get("command", "")
    if not isinstance(command, str):
        return None

    if is_dangerous_rm_command(command):
        return DENY, (
            "recursive, wildcard or privileged delete detected. Delete named "
            "paths explicitly instead."
        )

    if bash_touches_sensitive_file(command):
        return ASK, (
            "this command names a .env/secrets.sh file, which may hold live "
            "credentials. Approve only if the file is not being read out."
        )

    if check_env_var_lookup(command):
        return ASK, (
            "this command prints environment variable contents, which may be "
            "secrets. Approve only if you want the value in the transcript."
        )

    if is_github_write_command(command):
        return ASK, (
            "this publishes outward — pushing commits, or posting/merging on "
            "GitHub. Approve only if you asked for it."
        )

    return None


# One log for every project, outside any working tree. JSON Lines so a single
# call is an append — a JSON array would mean re-reading and re-serialising the
# whole history on every tool call.
_LOG_PATH = Path.home() / ".claude" / "logs" / "pre_tool_use.jsonl"
_LOG_MAX_BYTES = 5 * 1024 * 1024


def log_call(input_data: dict, decision: tuple[str, str] | None) -> None:
    """Append the call, and any verdict on it, to the audit log."""
    record = dict(input_data)
    if decision:
        record["hook_decision"] = {"action": decision[0], "reason": decision[1]}

    _LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    if _LOG_PATH.exists() and _LOG_PATH.stat().st_size > _LOG_MAX_BYTES:
        _LOG_PATH.replace(_LOG_PATH.with_name(_LOG_PATH.name + ".1"))

    with open(_LOG_PATH, "a") as f:
        f.write(json.dumps(record) + "\n")


def main() -> None:
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_input = input_data.get("tool_input") or {}
    decision = None
    try:
        decision = evaluate(input_data.get("tool_name", ""), tool_input)
    except Exception as exc:
        # Fail open, but never silently: a broken rule must not brick the CLI,
        # and must not look like a clean bill of health either.
        print(f"pre_tool_use: rules failed, allowing call: {exc!r}", file=sys.stderr)

    # Logged before the verdict is applied, so blocked calls — the ones worth
    # auditing — end up in the log too.
    try:
        log_call(input_data, decision)
    except Exception as exc:
        print(f"pre_tool_use: logging failed: {exc!r}", file=sys.stderr)

    if decision is None:
        sys.exit(0)

    action, reason = decision
    if action == DENY:
        print(f"BLOCKED: {reason}", file=sys.stderr)
        sys.exit(2)  # Exit code 2 blocks the tool call and shows stderr to Claude

    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "ask",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
