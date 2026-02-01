import type { Phase, ControlState, UnixSeconds } from "../shared/types";

export type SolumSnapshot = {
  version: "0.0.1";
  time: UnixSeconds;

  phase: Phase;
  controlState: ControlState;

  notes?: string;
};
