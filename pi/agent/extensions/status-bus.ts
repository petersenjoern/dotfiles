/**
 * Pi Agent Status Bus
 *
 * Wires `pi-status-bucket.py` into pi's agent lifecycle and UI prompt events
 * so /tmp/pi-agent-status/ reflects pi's activity—same pattern as Claude
 * Code's status_hook.py → tmux-cc-indicator.
 *
 * States emitted to /tmp/pi-agent-status/<tmux_pane>:
 *   "working"   → pi is actively running a turn or tool
 *   "attention" → pi is blocked waiting on user input/confirmation
 *   "idle"      → pi has settled or shut down
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
	pi.on("agent_start", async () => emitState("working"));

	pi.on("ui_prompt_start", async () => emitState("attention"));

	pi.on("ui_prompt_end", async (_event, ctx) => {
		emitState(ctx.isIdle() ? "idle" : "working");
	});

	pi.on("agent_settled", async () => emitState("idle"));

	pi.on("session_shutdown", async () => emitState("idle"));
}
