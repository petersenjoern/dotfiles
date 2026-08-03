# Communication Style
- Be concise and direct. Do not use filler phrases like "Certainly!" or "Here is the code."
- Never apologize for mistakes; just fix them and move on.
- When explaining code, focus only on the non-obvious logic.

# Git Workflow
- Always branch out before making experimental changes (use `git cob <branch>`).
- When writing commit messages, use concise, imperative language (e.g., "Fix database race condition" not "Fixed...").
- Do not commit without running `git diff` or `git status` first to verify the scope of changes.

# Environment
- The host system uses Zsh and the Omarchy desktop environment.
- Use modern CLI tools like `rg` (ripgrep) and `fd` instead of `grep` and `find` when executing bash commands, as they are faster and respect `.gitignore`.

# Coding Standards
- If a file is large, only show the exact snippets you are changing.
- Always include explicit type-hints and return types in Python or TypeScript unless it's a quick throwaway script.

# Architecture & API Design
- **Strict 3-Tier Architecture**:
  1. **Routers**: Handle HTTP, request validation, and Dependency Injection. No business logic.
  2. **Services**: Contain pure business logic. They must depend on interfaces, not concrete implementations.
  3. **Repositories**: Handle external data access (DBs, third-party APIs).
- **Protocols for DI**: Use structural subtyping (`typing.Protocol`) to define interface contracts for Services to rely on. Inject concrete Repositories into Services at the Router level.

# Testing Strategy (Avoiding Mocks)
- **Legacy Systems**: Respect the existing testing conventions of the repository you are working in. Do not refactor existing tests using `unittest.mock.patch` unless explicitly asked.
- **New Code**: For new services, ban the use of `patch` and `MagicMock` where possible.
- **Stateful Fakes**: For unit testing Services, prefer creating "Fake" implementations of your DI Protocols (e.g., `InMemoryUserRepository` using Python `dict`/`list` for state) rather than mocking return values. Inject these Fakes explicitly.
- **Factories & Random Data**: Populate your Fakes dynamically using factory patterns (e.g., `polyfactory`, `Faker`) to avoid hardcoded static data and expose edge cases.
- **Integration via Testcontainers**: When testing Repositories, prefer testing against real database engines using ephemeral Docker containers (e.g., `testcontainers-python`) instead of mocking the DB client.
- **HTTP Cassettes**: For 3rd-party API clients, use record/replay tools (`vcrpy`, `respx`, or `pytest-httpx`) instead of mocking `httpx`/`requests`.

# Error Handling
- **Domain Exceptions**: Services and Repositories must raise custom Domain Exceptions (e.g., `UserNotFoundError`), NEVER framework-specific exceptions like FastAPI's `HTTPException`.
- **Exception Mapping**: Catch Domain Exceptions in the Router layer and map them to the appropriate HTTP status codes and responses.

# Type Safety & Linting
- Never use `# type: ignore`, `@ts-ignore`, or `# noqa` to bypass type checkers or linters unless absolutely unavoidable. If used, it must be accompanied by an inline comment explaining exactly *why* the checker is wrong.
- Prefer generics (`TypeVar`), overloads, and strict type narrowing (e.g., `isinstance`) over using `Any` or `Any/unknown` casting.

# Refactoring & Cleanup
- When replacing or rewriting logic, **delete** the old code. Do not leave it commented out. Version control (Git) remembers it.
- Keep imports logically grouped and sorted (Standard Library → Third Party → Local/Internal).
- Prefer early returns (guard clauses) to reduce nesting and cyclomatic complexity.

# Observability
- Do not use `print()`. Always use the project's configured structured logger (e.g., `structlog`).
- Bind contextual data to logs (e.g., `logger.bind(user_id=...)`) rather than using string interpolation in the log message itself.

# Security
- Never hardcode secrets, API keys, or passwords, even in test data. Always read from environment variables or use dummy safe values (e.g., `sk-test-...`) for testing.
