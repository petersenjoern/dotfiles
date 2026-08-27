/**
 * Block Dangerous Commands Extension
 *
 * Wires the existing Claude Code hook scripts into pi's `tool_call` /
 * `tool_result` events, so the same safety rules gate both agents from a
 * single source of truth.
 *
 * Source of truth: ~/repos/personal/dotfiles/
 *   pi/agent/extensions/  →  ~/.pi/agent/extensions/  (dev-env-omarchy sync)
 *   claude/hooks/         →  ~/.claude/hooks/         (dev-env-omarchy sync)
 *
 * PreToolUse  (pre_tool_use.py)  → pi `tool_call`  : can block or ask.
 * PostToolUse (post_tool_use.py) → pi `tool_result`: feeds lint output back.
 *
 * The Python scripts speak Claude Code's stdin protocol:
 *   stdin:  {"tool_name": "Bash", "tool_input": {"command": "..."}}
 *   exit 0, no stdout                       → allow
 *   exit 0, JSON {hookSpecificOutput.permissionDecision:"ask"} → ask user
 *   exit 2, stderr "BLOCKED: ..."           → deny (stderr is the reason)
 *
 * pi tool names/inputs are mapped to Claude Code's format before invoking:
 *   bash  → Bash   {command}
 *   read  → Read   {file_path}
 *   write → Write  {file_path}
 *   edit  → Edit   {file_path}
 *
 * Scripts are expected at ~/.claude/hooks/ (synced from dotfiles by
 * dev-env-omarchy). Override with PI_SAFETY_HOOKS_DIR env var.
 */

import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const CLAUDE_HOOKS_DIR = join(homedir(), ".claude", "hooks");

function resolveHooksDir(): string {
	const fromEnv = process.env.PI_SAFETY_HOOKS_DIR;
	if (fromEnv && existsSync(fromEnv)) return fromEnv;
	return CLAUDE_HOOKS_DIR;
}

const PRE_TIMEOUT_MS = 30_000;
const POST_TIMEOUT_MS = 60_000; // mirrors Claude's PostToolUse timeout

/** A normalized verdict from a hook script. */
type Verdict =
	| { action: "allow" }
	| { action: "ask"; reason: string }
	| { action: "deny"; reason: string };

/**
 * Map a pi tool call to Claude Code's {tool_name, tool_input} hook payload.
 * Returns null for tools the hooks don't inspect (only bash + file tools).
 */
function toClaudePayload(
	toolName: string,
	input: Record<string, unknown> | undefined,
): { tool_name: string; tool_input: Record<string, unknown> } | null {
	const safeInput = (input ?? {}) as Record<string, unknown>;
	switch (toolName) {
		case "bash":
			return { tool_name: "Bash", tool_input: { command: safeInput.command ?? "" } };
		case "read":
			return { tool_name: "Read", tool_input: { file_path: safeInput.path ?? "" } };
		case "write":
			return { tool_name: "Write", tool_input: { file_path: safeInput.path ?? "" } };
		case "edit":
			return { tool_name: "Edit", tool_input: { file_path: safeInput.path ?? "" } };
		default:
			return null; // hooks only inspect bash + file tools
	}
}

/** Run a hook script and translate its exit/stdout/stderr into a Verdict. */
async function runHook(
	scriptPath: string,
	payload: Record<string, unknown>,
	timeoutMs: number,
	failOpenVerdict: Verdict,
	onFailOpen?: (detail: string) => void,
): Promise<Verdict> {
	const stdin = JSON.stringify(payload);
	let stdout = "";
	let stderr = "";
	let spawnError = "";
	let exitCode = 0;
	let timedOut = false;

	await new Promise<void>((resolve) => {
		const child = spawn("uv", ["run", "--script", scriptPath], {
			stdio: ["pipe", "pipe", "pipe"],
		});

		const timer = setTimeout(() => {
			timedOut = true;
			child.kill("SIGTERM");
		}, timeoutMs);

		child.stdout.on("data", (d: Buffer) => (stdout += d.toString()));
		child.stderr.on("data", (d: Buffer) => (stderr += d.toString()));
		// e.g. `uv` not on PATH / not resolvable → the hook never runs at all.
		child.on("error", (err: Error) => {
			clearTimeout(timer);
			spawnError = err.message;
			resolve();
		});
		child.on("close", (code) => {
			clearTimeout(timer);
			exitCode = code ?? 1;
			resolve();
		});

		// A failed spawn makes stdin unwritable; swallow the EPIPE so it doesn't
		// surface as an unhandled 'error' event.
		child.stdin.on("error", () => {});
		child.stdin.end(stdin);
	});

	// The hook binary couldn't be launched — treat like any other hook failure:
	// fail open, but surface it so the gate isn't silently off.
	if (spawnError) {
		const detail = `${scriptPath} could not run: ${spawnError}`;
		console.error(`block-dangerous-commands: ${detail}`);
		onFailOpen?.(detail);
		return failOpenVerdict;
	}

	if (timedOut) {
		const detail = `${scriptPath} timed out after ${timeoutMs}ms`;
		console.error(`block-dangerous-commands: ${detail}, failing open`);
		onFailOpen?.(detail);
		return failOpenVerdict;
	}

	// exit 2 → deny, stderr carries the reason.
	if (exitCode === 2) {
		const reason = stderr.trim().replace(/^BLOCKED:\s*/i, "") || "blocked by safety hook";
		return { action: "deny", reason };
	}

	// Any other non-zero exit → the hook itself broke. Fail open, but loudly.
	if (exitCode !== 0) {
		const detail = `${scriptPath} exited ${exitCode}: ${stderr.trim()}`;
		console.error(`block-dangerous-commands: ${detail}`);
		onFailOpen?.(detail);
		return failOpenVerdict;
	}

	// exit 0 → allow, unless stdout carries an "ask" decision.
	const trimmed = stdout.trim();
	if (!trimmed) return { action: "allow" };

	try {
		const parsed = JSON.parse(trimmed) as {
			hookSpecificOutput?: {
				permissionDecision?: string;
				permissionDecisionReason?: string;
			};
		};
		const decision = parsed.hookSpecificOutput?.permissionDecision;
		const reason = parsed.hookSpecificOutput?.permissionDecisionReason ?? "requires approval";
		if (decision === "ask") return { action: "ask", reason };
		if (decision === "deny") return { action: "deny", reason };
		return { action: "allow" };
	} catch {
		// exit 0 with non-JSON stdout → treat as allow (script's contract is JSON or nothing).
		return { action: "allow" };
	}
}

export default function (pi: ExtensionAPI): void {
	const hooksDir = resolveHooksDir();
	const preTool = join(hooksDir, "pre_tool_use.py");
	const postTool = join(hooksDir, "post_tool_use.py");

	// The pre-hook is the safety-critical path. It fails open on any problem — a
	// broken ruleset must not brick the agent — but a silently-off gate is worse
	// than a visibly-off one, so each failure mode is surfaced once, loudly.
	//   - "missing": the script isn't synced in yet.
	//   - "broken":  it's there but couldn't run (uv absent, timeout, crash).
	// Both mean the same thing to the user: this call was NOT checked.
	const warned = { missing: false, broken: false };
	function warnGateOff(ctx: ExtensionContext, kind: "missing" | "broken", detail: string): void {
		if (warned[kind]) return;
		warned[kind] = true;
		const msg =
			kind === "missing"
				? `block-dangerous-commands: hook scripts missing at ${hooksDir}; safety gate is OFF`
				: `block-dangerous-commands: safety hook failed to run (${detail}); calls are NOT being checked`;
		console.error(msg);
		if (ctx.hasUI) ctx.ui.notify(`⚠ ${msg}`, "warning");
	}

	// PreToolUse: gate the call before it runs.
	pi.on("tool_call", async (event, ctx) => {
		const payload = toClaudePayload(event.toolName, event.input);
		if (payload === null) return; // not a tool the hook inspects

		// No script → running it would just spawn a failing `uv`. Skip the spawn,
		// fail open, and warn once instead of on every call.
		if (!existsSync(preTool)) {
			warnGateOff(ctx, "missing", "");
			return;
		}

		const verdict = await runHook(
			preTool,
			payload,
			PRE_TIMEOUT_MS,
			{ action: "allow" }, // fail open on hook error
			(detail) => warnGateOff(ctx, "broken", detail),
		);

		if (verdict.action === "deny") {
			if (ctx.hasUI) ctx.ui.notify(`⛔ ${verdict.reason}`, "warning");
			return { block: true, reason: verdict.reason };
		}

		if (verdict.action === "ask") {
			// No UI to confirm with → block, so a heuristic never silently runs.
			if (!ctx.hasUI) {
				return { block: true, reason: verdict.reason };
			}
			const header = `Approve ${event.toolName}?`;
			const ok = await ctx.ui.confirm(header, verdict.reason);
			if (!ok) {
				return { block: true, reason: `User declined: ${verdict.reason}` };
			}
		}
		// action === "allow" → return undefined, call proceeds.
	});

	// PostToolUse: after edit/write, surface lint/type errors back to the model.
	pi.on("tool_result", async (event, _ctx) => {
		if (event.toolName !== "edit" && event.toolName !== "write") return;
		const payload = toClaudePayload(event.toolName, event.input);
		if (payload === null) return;
		if (!existsSync(postTool)) return; // not synced → no lint feedback, skip the failing spawn

		const verdict = await runHook(postTool, payload, POST_TIMEOUT_MS, {
			action: "allow",
		});

		// exit 2 → the script surfaced lint/type failures. Append them to the
		// tool result so the model sees the breakage it just caused and can fix
		// it in the same turn. The edit itself succeeded, so we don't mark
		// isError — we only add the diagnostics as extra context.
		if (verdict.action === "deny") {
			const lintNote = `\n[post-edit check]\n${verdict.reason}`;
			return {
				content: [
					...(event.content ?? []),
					{ type: "text" as const, text: lintNote },
				],
			};
		}
		// allow → no modification.
	});
}