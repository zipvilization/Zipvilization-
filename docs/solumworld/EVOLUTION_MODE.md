# SolumWorld — Evolution Mode (Canonical Spec)

## 1. Purpose

Evolution Mode defines how SolumWorld changes over time.

It allows:
- Observing the world at any past moment
- Replaying history deterministically
- Understanding how the present state emerged

Evolution Mode does NOT:
- Modify the rules of simulation
- Allow rewrites of the past
- Create alternative timelines

There is one history.
Evolution Mode reveals it.

---

## 2. Core Principles

1. Single Timeline  
   SolumWorld has one canonical timeline.
   There are no branches, forks, or parallel histories.

2. Deterministic Progression  
   Given the same initial state and inputs,
   evolution always produces the same result.

3. Immutable Past  
   Once a state is finalized, it cannot be altered.

4. Snapshot-Based  
   History is accessed through snapshots,
   not by re-running live simulation.

5. Zoom-Agnostic  
   Evolution rules apply identically at all zoom levels.

---

## 3. Moment 0 (Genesis)

Moment 0 is the first valid SolumWorld state.

Properties:
- No production history
- No accumulated resources
- Initial Zip populations only
- Initial parcel allocations

All future states derive from Moment 0.

If Moment 0 is incorrect, the entire timeline is invalid.

---

## 4. Time Units

Evolution advances in discrete steps.

Canonical units:
- Tick (smallest unit, internal)
- Cycle (economic / production unit)
- Epoch (group of cycles, optional abstraction)

Rules:
- All simulation advances in ticks
- Cycles are derived from ticks
- Epochs are descriptive, not mechanical

---

## 5. Snapshots

A snapshot is a frozen representation of SolumWorld at a given time.

Snapshots:
- Are immutable once created
- Reference canonical simulation data
- Are indexed by time (tick or cycle)

Snapshots may exist at:
- Parcel level (Zoom 3)
- Aggregated levels (Zoom 2 → Zoom 0)

Lower zoom snapshots are always derived from Zoom 3 snapshots.

---

## 6. Replay Mode

Replay Mode reconstructs world evolution by iterating snapshots.

Rules:
- Replay never mutates live state
- Replay uses stored snapshots or deterministic recomputation
- Replay speed does not affect outcomes

Replay can be:
- Sequential (from Moment 0)
- Random-access (jump to snapshot N)

---

## 7. Evolution vs Live Simulation

Live simulation:
- Advances the current state forward
- Produces new snapshots

Evolution Mode:
- Reads existing snapshots
- Never writes new canonical state

No system may:
- Use Evolution Mode to influence live simulation
- Inject replay data into active state

---

## 8. Zoom Interaction

Evolution Mode respects Zoom Rules.

Rules:
- A snapshot exists first at Zoom 3
- Higher zoom snapshots are aggregations
- Zooming during replay does not change time

Invalid:
- Showing different times at different zooms
- Mixing snapshots from different ticks

---

## 9. Information Loss Over Time

Information loss is cumulative and intentional.

Rules:
- Older snapshots may lose fine-grained detail
- Aggregated historical data may be compressed
- Loss is always monotonic, never reversed

Canonical source remains the earliest available snapshot.

---

## 10. Persistence Strategy

Snapshots may be stored as:
- Full state dumps (early stages)
- Delta-based diffs (advanced stages)
- Hybrid models

Storage strategy does not affect semantics.

---

## 11. Failure Modes

If snapshots are missing:
- Replay must halt or degrade gracefully
- No data fabrication is allowed

If determinism breaks:
- Timeline is considered corrupted
- System must flag integrity failure

---

## 12. Canonical Rule

If replayed history does not match the present state,
the present state is invalid.

Evolution Mode is the judge of coherence.

---

## 13. Final Constraint

Any SolumWorld implementation that:
- Alters the past
- Forks history
- Simulates multiple timelines

is not compatible with Zipvilization.
