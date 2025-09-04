#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///


# PreToolUse Hook - CAN BLOCK TOOL EXECUTION Primary Control Point: Intercepts
# tool calls before they execute Exit Code 2 Behavior: Blocks the tool call
# entirely, shows error message to Claude Use Cases: Security validation,
# parameter checking, dangerous command prevention


import json
import sys
import re
from pathlib import Path


def is_dangerous_rm_command(command: str) -> bool:
    """
    Comprehensive detection of dangerous rm commands.
    Matches various forms of rm -rf and similar destructive patterns.
    """
    normalized_command = " ".join(command.lower().split())

    # Pattern 1: Standard rm -rf variations
    patterns = [
        r"\brm\s+.*-[a-z]*r[a-z]*f",  # rm -rf, rm -fr, rm -Rf, etc.
        r"\brm\s+.*-[a-z]*f[a-z]*r",  # rm -fr variations
        r"\brm\s+--recursive\s+--force",  # rm --recursive --force
        r"\brm\s+--force\s+--recursive",  # rm --force --recursive
        r"\brm\s+-r\s+.*-f",  # rm -r ... -f
        r"\brm\s+-f\s+.*-r",  # rm -f ... -r
        r"rm\s+.*-[rf]",  # rm -rf variants
        r"sudo\s+rm",  # sudo rm commands
        r"chmod\s+777",  # Dangerous permissions
        r">\s*/etc/",  # Writing to system directories
    ]

    # Check for dangerous patterns
    for pattern in patterns:
        if re.search(pattern, normalized_command, re.IGNORECASE):
            return True

    # Pattern 2: Check for rm with recursive flag targeting dangerous paths
    dangerous_paths = [
        r"/",  # Root directory
        r"/\*",  # Root with wildcard
        r"~",  # Home directory
        r"~/",  # Home directory path
        r"\$HOME",  # Home environment variable
        r"\.\.",  # Parent directory references
        r"\*",  # Wildcards in general rm -rf context
        r"\.",  # Current directory
        r"\.\s*$",  # Current directory at end of command
    ]

    if re.search(r"\brm\s+.*-[a-z]*r", normalized_command):  # If rm has recursive flag
        for path in dangerous_paths:
            if re.search(path, normalized_command):
                return True

    return False


def check_sensitive_file_access(tool_name: str, tool_input: dict[str, str]) -> bool:
    """
    Check if any tool is trying to access .env files containing sensitive data.
    """

    sensitive_files = [".env", "secrets.sh"]
    non_sensitive_files = [".env.sample"]
    tool_names = ["Read", "Edit", "MultiEdit", "Write", "Bash"]
    file_path = tool_input.get("file_path", "")
    file_path_suffix = file_path.split("/")[-1] if file_path else ""

    command = tool_input.get("command", "")

    if not file_path:
        return False

    if (
        tool_name in tool_names
        and file_path_suffix in sensitive_files
        and (file_path_suffix not in non_sensitive_files)
    ):
        return True

    if tool_name == "Bash":
        # Pattern to detect .env file access (but allow .env.sample) and secrets.sh access
        env_patterns = [
            r"\b(\.env(?!\.sample)|secrets\.sh)\b",  # .env (not .env.sample) or secrets.sh
            r"cat\s+.*(\.env(?!\.sample)|secrets\.sh)\b",  # cat .env or secrets.sh
            r"echo\s+.*>\s*(\.env(?!\.sample)|secrets\.sh)\b",  # echo > .env or secrets.sh
            r"touch\s+.*(\.env(?!\.sample)|secrets\.sh)\b",  # touch .env or secrets.sh
            r"cp\s+.*(\.env(?!\.sample)|secrets\.sh)\b",  # cp .env or secrets.sh
            r"mv\s+.*(\.env(?!\.sample)|secrets\.sh)\b",  # mv .env or secrets.sh
        ]

        for pattern in env_patterns:
            if re.search(pattern, command):
                return True

    return False


def main():
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)

        tool_name = input_data.get("tool_name", "")
        tool_input = input_data.get("tool_input", {})

        # Check for .env file access (blocks access to sensitive environment files)
        if check_sensitive_file_access(tool_name, tool_input):
            print(
                "BLOCKED: Access to .env/secrets.sh files containing sensitive data is prohibited",
                file=sys.stderr,
            )
            print("Use .env.sample for template files instead", file=sys.stderr)
            sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude

        # Check for dangerous rm -rf commands
        if tool_name == "Bash":
            command = tool_input.get("command", "")

            # Block rm -rf commands with comprehensive pattern matching
            if is_dangerous_rm_command(command):
                print(
                    "BLOCKED: Dangerous rm command detected and prevented",
                    file=sys.stderr,
                )
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude

        # Ensure log directory exists
        log_dir = Path.cwd() / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        log_path = log_dir / "pre_tool_use.json"

        # Read existing log data or initialize empty list
        if log_path.exists():
            with open(log_path, "r") as f:
                try:
                    log_data = json.load(f)
                except (json.JSONDecodeError, ValueError):
                    log_data = []
        else:
            log_data = []

        # Append new data
        log_data.append(input_data)

        # Write back to file with formatting
        with open(log_path, "w") as f:
            json.dump(log_data, f, indent=2)

        sys.exit(0)

    except json.JSONDecodeError:
        # Gracefully handle JSON decode errors
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)


if __name__ == "__main__":
    main()
