Look at the code you just wrote and strip it to the absolute minimum that solves the problem.

Rules:
- Remove every abstraction that isn't pulling its weight. If it's only used once, inline it.
- Reduce layers. If something can be done in fewer files, functions, or indirections — do it.
- Delete defensive code for scenarios that can't actually happen in this context.
- Prefer standard library and language primitives over custom helpers.
- If you added configurability or extensibility that wasn't asked for, remove it.

Show me the simplified version. Then list what you removed and why each removal is safe.
