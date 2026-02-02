STATE_VALIDATION — SolumWorld (Canonical Spec)

This document defines how state validation works in SolumWorld.
It is a source-of-truth specification, not an implementation.

1. Purpose
State validation guarantees that every visible or persisted state
in SolumWorld is:
- Deterministic
- Consistent with prior history
- Valid for its zoom level
- Aligned with evolution rules

If a state fails validation, it MUST NOT be accepted.

2. Validation Scope
Validation applies to:
- All zoom levels (Z0 → Zmax)
- All state transitions
- All derived or aggregated states
- All historical replays

3. Validation Principles
- Fail-closed: invalid state = rejected state
- Deterministic only: no probabilistic checks
- Local + global consistency
- No UI or narrative influence

4. Core Validation Axes
4.1 Structural
- Required fields present
- No unknown fields
- Schema version matches

4.2 Temporal
- Timestamps monotonic
- No future state
- Evolution counters consistent

4.3 Quantitative
- Solum balances conserved
- No negative quantities
- Totals match parent zoom

4.4 Evolutionary
- State evolution follows allowed transitions
- No skipping of mandatory phases
- No rollback without explicit rule

5. Zoom-Level Validation
Each zoom level defines:
- Its own validation schema
- Its aggregation rules from lower zooms
- Its projection rules to higher zooms

A state valid at Z(n) does NOT imply validity at Z(n+1).

6. Cross-Zoom Consistency
- Aggregations must equal sum of children
- Projections must be lossless within defined tolerance
- No hidden state between zooms

7. Validation Timing
Validation occurs:
- Before state acceptance
- After every transition
- During replay
- During snapshot restore

8. Rejection Handling
On validation failure:
- State is rejected
- Transition aborted
- No partial persistence allowed

9. AI Interaction
AI systems may:
- Propose state changes
- Simulate futures

AI systems may NOT:
- Override validation
- Force acceptance
- Alter validation rules

10. Canonical Status
This document is canonical.
Any implementation not complying with this spec
is NOT a valid SolumWorld system.
