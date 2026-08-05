#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pytest"]
# ///

"""Rule tests for the PreToolUse hook: `uv run claude/hooks/test_pre_tool_use.py`.

The rules are regex-heavy and fail open, so a mistake is invisible in normal
use — every case here is either a block that must keep working or a false
positive that must stay fixed.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent))

from pre_tool_use import ASK, DENY, evaluate  # noqa: E402


def verdict(command: str) -> str | None:
    decision = evaluate("Bash", {"command": command})
    return decision[0] if decision else None


@pytest.mark.parametrize(
    "command",
    [
        "rm -rf /",
        "rm -rf node_modules",
        "rm -fr build",
        "rm --recursive dist",
        "rm *",
        "rm ./*",
        "rm -f ~",
        "cd /tmp && rm -rf foo",
        "sudo rm file.txt",
        "find . -name '*.pyc' | xargs rm -rf",
        "find . -type d -exec rm -rf {} +",
        "chmod 777 /usr/bin",
        "echo pwned > /etc/passwd",
    ],
)
def test_destructive_commands_are_denied(command):
    assert verdict(command) == DENY


@pytest.mark.parametrize(
    "command",
    [
        "rm file.txt",
        "rm -f build/artifact.tar.gz",
        "git rm --cached secret.txt",
        "npm rm left-pad",
        "rm -i notes.md",
        "grep -rn rm .",
    ],
)
def test_targeted_deletes_pass(command):
    assert verdict(command) is None


@pytest.mark.parametrize(
    "command",
    [
        "cat .env",
        "cat /home/user/app/.env",
        "cp .env /tmp/copy",
        "mv .env.local /tmp",
        "echo FOO=1 > .env",
        "source secrets.sh",
    ],
)
def test_secret_files_via_bash_ask(command):
    assert verdict(command) == ASK


@pytest.mark.parametrize(
    "command",
    [
        "cat .env.sample",
        "cp .env.example .env.sample",
        "cat .env.1password",
    ],
)
def test_env_templates_pass(command):
    assert verdict(command) is None


@pytest.mark.parametrize(
    "tool",
    ["Read", "Edit", "Write", "MultiEdit"],
)
def test_secret_files_via_file_tools_are_denied(tool):
    assert evaluate(tool, {"file_path": "/home/user/app/.env"})[0] == DENY


def test_env_template_via_file_tool_passes():
    assert evaluate("Read", {"file_path": "/home/user/app/.env.sample"}) is None


@pytest.mark.parametrize(
    "command",
    [
        "printenv",
        "env",
        "set",
        "declare -p",
        "export -p",
        "compgen -v",
        "echo $OPENAI_API_KEY",
        "echo ${GITHUB_TOKEN}",
        "echo $tpuf_api_key",
        "printf '%s' $AWS_SECRET_ACCESS_KEY",
        'echo "$(env)"',
        "echo ${!X}",
        "echo $DATABASE_URL",
    ],
)
def test_env_disclosure_asks(command):
    assert verdict(command) == ASK


@pytest.mark.parametrize(
    "command",
    [
        'echo "$HOME/foo"',
        'cat "$HOME/.config/app/config.toml"',
        "echo $PATH",
        "echo $PWD",
        "set -e",
        "set -euo pipefail",
        "env FOO=bar python script.py",
        'for f in *.py; do echo "$f"; done',
        "aws s3 ls",
        "cat README.md",
    ],
)
def test_ordinary_shell_usage_passes(command):
    assert verdict(command) is None


@pytest.mark.parametrize(
    "command",
    [
        "git push",
        "git push origin main",
        "cd repo && git push --force",
        "gh pr create --fill",
        "gh pr comment 12 --body hi",
        "gh pr merge 12",
        "gh issue close 3",
        "gh release create v1.0.0",
        "gh api -X POST /repos/o/r/issues",
        "gh api /repos/o/r/issues -f title=bug",
    ],
)
def test_outward_facing_github_writes_ask(command):
    assert verdict(command) == ASK


@pytest.mark.parametrize(
    "command",
    [
        "git status",
        "git log --oneline -5",
        "git fetch origin",
        "gh pr view 12",
        "gh pr list",
        "gh pr diff 12",
        "gh api /repos/o/r/pulls/12",
        "gh api -X GET /search/issues -f q=foo",
    ],
)
def test_read_only_git_and_gh_pass(command):
    assert verdict(command) is None


def test_unparseable_input_does_not_crash():
    assert evaluate("Bash", {}) is None
    assert evaluate("Bash", {"command": None}) is None
    assert evaluate("", {}) is None


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q"]))
