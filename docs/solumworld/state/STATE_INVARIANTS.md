STATE_INVARIANTS — SolumWorld / Zipvilization

Purpose
-------
Define the non-negotiable invariants that must ALWAYS hold true in SolumWorld,
regardless of zoom level, evolution stage, or implementation layer.

Invariants are the backbone of determinism.
If an invariant is broken, the state is invalid by definition.

Core Principles
---------------
- Fail-closed: if an invariant cannot be validated, the state is rejected.
- Deterministic: same inputs MUST always lead to the same invariant checks.
- Zoom-agnostic: invariants apply from Zoom 0 to Max Zoom.
- Time-agnostic: invariants apply across all historical states.

Global Invariants
-----------------
1. Conservation of Solum
   - Total Solum supply is conserved at all times.
   - No implicit minting or destruction outside defined rules.

2. Spatial Consistency
   - Every Solum unit occupies exactly one coordinate at a given zoom.
   - No overlapping ownership at the same resolution.

3. Ownership Determinism
   - Each Solum unit has exactly one owner or is explicitly unowned.
   - Ownership transitions are atomic.

4. Zoom Coherence
   - Zoom N must be derivable from Zoom N-1 without ambiguity.
   - Aggregation and subdivision preserve total value.

5. Evolution Integrity
   - Evolution can only move forward in time.
   - Past states are immutable.

6. State Completeness
   - A valid state must define:
     - time
     - zoom
     - ownership
     - resources (if applicable)

Violation Handling
------------------
- Any invariant violation invalidates the entire state.
- Partial validity is not allowed.
- Recovery must use rollback mechanisms, never mutation.

Canonical Status
----------------
This document is canonical.
Any implementation contradicting these invariants is non-compliant by design.
