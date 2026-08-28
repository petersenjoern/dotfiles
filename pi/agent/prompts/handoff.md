---
description: Hand an already-decided plan to the cheap implement tier, gated and reviewed
argument-hint: "<plan-file> [worktree] [notes]"
---

Hand off implementation of the plan in `$1` to the `implement` subagent.

First read `$1` yourself and check it is actually handoff-ready. A plan is
handoff-ready only when it states all three of:

1. every file to change, by path;
2. what changes in each file, concretely enough that no design decision is left;
3. one shell command that proves the change works (tests, lint, a build, a
   script — but a real command that exits non-zero on failure).

If any of the three is missing, do NOT hand off. Say which one is missing and
offer to finish the plan first. That check is the whole point of this workflow:
if the plan cannot be written down completely, the task is not mechanical and
you should keep it yourself.

When the plan is ready, launch it with the `subagent` tool as a workflow. Pass
the plan by path so the child reads the file itself. Use the verify command from
the plan as the `gate`:

```js
subagent({ workflowScript: `
  const impl = await runs.run("impl", {
    agent: "implement",
    task: "Apply the approved plan in <plan-path>. Read it first. Change only the files it names. Run its verify command and report the real result.",
    gate: "<verify command from the plan>"
  });
  const review = await runs.run("review", {
    agent: "reviewer",
    context: "fresh",
    task: "Review the working-tree diff against the plan in <plan-path>. Check only: does the diff do what the plan says, no more and no less; are there bugs; did anything drift out of scope. Read the plan and the diff from disk. Do not edit files.",
    output: false
  });
  return { impl: impl.output, review: review.output };
` , async: false })
```

Do not set `turnBudget` or a hard `toolBudget` on the implement child — cutting a
writer mid-edit leaves the tree half-changed.

If the invocation contains the word `worktree`, add `worktree: true` to the
implement run so the child works on an isolated branch, and report the handoff
manifest path instead of expecting changes in the working tree.

When the workflow returns, report in this order:

- what the gate did: the command, and whether it actually passed;
- what the child changed, and anything it changed that the plan did not name;
- what the reviewer found, separated into things worth fixing now and noise;
- anything the child escalated or was blocked on.

Then stop and ask before applying review fixes, unless I already told you to
address them. Prefer resuming the same implement child for fixes over starting a
new one, and keep fixes inside the original plan's scope.

If the child comes back blocked with `contact_supervisor`, answer the decision
yourself only when the plan already implies the answer. If it is a real design
decision, bring it to me — that is the signal the task was never handoff-ready.

Additional instructions for this handoff:

${@:2}
