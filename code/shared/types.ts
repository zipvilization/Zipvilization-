export type HexAddress = `0x${string}`;

export type Phase = "Genesis" | "Phase1" | "Paused";
export type ControlState = "Human" | "Hybrid";

/**
 * Deterministic clock representation for snapshots.
 * Keep it simple until infra choices are explicit.
 */
export type UnixSeconds = number;
