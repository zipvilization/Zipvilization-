import type { Phase, ControlState, UnixSeconds } from "../shared/types";
import type { SolumSnapshot } from "./snapshot";

/**
 * Phase 0 deterministic simulator.
 * No chain access. No UI. No business interpretation.
 *
 * Purpose:
 * - Provide a minimal state machine consistent with SolumCore boundaries
 * - Produce deterministic snapshots for testing and documentation
 */
export class SolumSimulator {
  private phase: Phase = "Genesis";
  private controlState: ControlState = "Human";

  setControlState(next: ControlState) {
    this.controlState = next;
  }

  setPhase(next: Phase) {
    this.phase = next;
  }

  pause() {
    this.phase = "Paused";
  }

  resumeToPhase1() {
    this.phase = "Phase1";
  }

  snapshot(time: UnixSeconds, notes?: string): SolumSnapshot {
    return {
      version: "0.0.1",
      time,
      phase: this.phase,
      controlState: this.controlState,
      notes,
    };
  }
}
