/**
 * Pi Agent Status Bus
 *
 * Wires the `pi-status-bucket.py` into pi's `tool_call` / `tool_result`
 * events so /tmp/pi-agent-status/ reflects pi's activity—same pattern as Claude
 * Code's status_hook.py → tmux-cc-indicator.
 *
 * States emitted to /tmp/pi-agent-status/<tmux_pane>:
 *   "working"   → pi is actively burning tokens
 *   "idle"      → pi finished a tool call
 *   "attention" → (reserved) agent is waiting for user
 */

import { existsSync } from "node:fs";
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const STATUS_BUCKET = join(homedir(), ".local", "scripts", "pi-status-bucket.py");

function emitState(state: "working" | "attention" | "idle"): void {
	if (!existsSync(STATUS_BUCKET)) return; // skip silently if not yet synced

	spawn("uv", ["run", "--script", STATUS_BUCKET, state], {
		stdio: ["ignore", "ignore", "ignore"],
		detached: true,
	}).unref();
}

export default function (pi: ExtensionAPI): void {
	pi.on("tool_call", async () => emitState("working"));

	pi.on("tool_result", async () => emitState("idle"));

	// If pi ever emits a confirmation event, we'd wire it to "attention" here.
	// For now, the tool result already resets the state, so "attention" is
	// implicit between the tool call and its result.
}
