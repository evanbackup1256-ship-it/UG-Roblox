// store.ts — Minimal reactive store fed by server Changed event

import { ReplicatedStorage } from "@rbxts/services";

export interface PlayerState {
	compute: number;
	totalEarned: number;
	jobs: number;
	owned: Map<string, number>;
	research: Map<string, number>;
	claimed: Map<string, boolean>;
	achievements: Map<string, boolean>;
	energy: number;
	data: number;
	prestigeTokens: number;
	boostUntil: number;
	boostReady: number;
	callsign: string;
}

type Listener = (state: PlayerState) => void;

const listeners = new Array<Listener>();
let currentState: PlayerState = {
	compute: 0,
	totalEarned: 0,
	jobs: 0,
	owned: new Map(),
	research: new Map(),
	claimed: new Map(),
	achievements: new Map(),
	energy: 100,
	data: 0,
	prestigeTokens: 0,
	boostUntil: 0,
	boostReady: 0,
	callsign: "Operator",
};

export function getState(): PlayerState {
	return currentState;
}

export function setState(nextState: PlayerState): void {
	currentState = nextState;
	for (const l of listeners) {
		task.spawn(() => l(nextState));
	}
}

export function subscribe(listener: Listener): () => void {
	listeners.push(listener);
	return () => {
		const idx = listeners.indexOf(listener);
		if (idx !== -1) listeners.remove(idx);
	};
}

/** Format large numbers: 1.23M, 456.7k, etc. */
export function fmt(val: number): string {
	if (val < 0) return "-" + fmt(-val);
	if (val < 1000) return tostring(math.floor(val + 0.5));
	const suffixes = ["k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"];
	const exp = math.min(math.floor(math.log(val) / math.log(1000)), suffixes.size());
	const scaled = val / math.pow(1000, exp);
	if (scaled < 10) return `${string.format("%.2f", scaled)}${suffixes[exp - 1]}`;
	if (scaled < 100) return `${string.format("%.1f", scaled)}${suffixes[exp - 1]}`;
	return `${string.format("%.0f", scaled)}${suffixes[exp - 1]}`;
}

/** Fire an action to the server and return the result. */
export function act(actionName: string, payload?: unknown): unknown {
	const Action = ReplicatedStorage.WaitForChild("DeckGame")
		.WaitForChild("Action") as RemoteFunction;
	return Action.InvokeServer(actionName, payload);
}

