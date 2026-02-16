## Workflow Rules

- Never commit or create PRs unless explicitly asked. I prefer to handle git operations myself.
- When the request is straightforward, skip brainstorming/option-listing and go
directly to implementation. Only brainstorm when explicitly asked or when the
problem is genuinely ambiguous.

## Code Changes

- Prefer minimal, targeted fixes over large refactors. Choose the smallest
change that solves the problem. Do not refactor surrounding code unless asked.
- After making multi-file changes, re-read all modified files to verify
consistency. Check that all references to renamed/removed functions, fields, or
types are updated across the entire codebase.

## Python Style

- Use modern type syntax: lowercase `dict`, `list`, `tuple` instead of `typing.Dict`, `typing.List`, `typing.Tuple`.
- Use `X | None` instead of `Optional[X]`.
- Default mutable arguments should use field defaults or None with factory patterns, never bare mutable defaults.
- Default to functional programming with pure functions. Only use classes when you need:
  - State that persists across method calls
  - Complex state initialization or lifecycle management
  - Clear object identity and encapsulation boundaries

