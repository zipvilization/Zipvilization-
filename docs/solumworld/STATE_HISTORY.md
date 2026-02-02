STATE_HISTORY — SolumWorld / Zipvilization

Purpose
-------
Define how SolumWorld state history is recorded, preserved, and interpreted.

State history is not a log.
It is an immutable timeline of validated world states.

Design Philosophy
-----------------
- Append-only
- Immutable
- Deterministic reconstruction
- Auditable by humans and AI

State Timeline
--------------
- Each state has a unique, monotonically increasing index.
- Each state references exactly one previous state (except Genesis).
- No branching in canonical history.

State Record Structure
----------------------
Each historical state includes:
- state_id
- previous_state_id
- timestamp
- zoom level
- validated invariants hash
- state data hash

Genesis State
-------------
- State 0 is Genesis.
- Genesis defines:
  - initial Solum distribution
  - base topology
  - initial ruleset
- Genesis can never be altered or replaced.

Reconstruction Rules
--------------------
- Any state can be reconstructed from Genesis + ordered transitions.
- If reconstruction fails, the state is invalid.

Access Patterns
---------------
- History is readable at any zoom.
- Higher zooms may aggregate multiple historical micro-states.

What History Is NOT
-------------------
- Not a gameplay log
- Not a reversible ledger
- Not mutable metadata

Canonical Status
----------------
History defines truth.
If it is not in history, it never happened.
