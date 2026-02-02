# SolumWorld — State Model (Canonical Spec)

## 1. Definition of State

A SolumWorld State is a complete, self-consistent snapshot
of the world at a specific moment in time.

It represents:
- What exists
- Where it exists
- In what quantity
- Under which rules

A state is not a view.
A state is the world.

---

## 2. Atomicity

The state is atomic.

This means:
- It is either fully valid or invalid
- Partial states are not allowed
- Incomplete updates are forbidden

No subsystem may observe or operate on a half-updated state.

---

## 3. Determinism

Given the same prior state and the same inputs,
the resulting state MUST be identical.

State transitions must be:
- Pure
- Deterministic
- Free of external entropy

Randomness must be seeded and reproducible.

---

## 4. State Components

A canonical SolumWorld state is composed of the following components:

### 4.1 Spatial Layer
- Parcel identifiers
- Parcel boundaries
- Parcel ownership (Solum-based)

### 4.2 Population Layer
- Zip entities
- Zip counts per parcel
- Zip roles (worker, idle, specialist, etc.)

### 4.3 Resource Layer
- Resource types
- Resource quantities
- Resource locations

### 4.4 Infrastructure Layer
- Built structures
- Production facilities
- Connectivity elements

### 4.5 Economic Layer
- Production outputs
- Consumption rates
- Transfers between parcels

### 4.6 Governance Layer (optional)
- Rules applied to zones or parcels
- Constraints or modifiers

Each layer must be serializable independently.

---

## 5. Canonical Representation

The state must have a canonical internal representation.

Rules:
- Field names are stable
- Ordering is deterministic
- Units are explicit
- No implicit defaults

If two serialized states differ byte-for-byte,
they are different states.

---

## 6. Validation Rules

A state is valid if and only if:

- Total resources are conserved (except when rules allow creation/destruction)
- Population counts are non-negative
- Parcel ownership sums match Solum allocation
- No entity exists outside a parcel
- All references are resolvable

Invalid states must be rejected immediately.

---

## 7. State Transitions

A state transition:
- Takes a valid state as input
- Applies a set of deterministic rules
- Produces exactly one new valid state

Transitions may include:
- Production
- Consumption
- Movement
- Construction
- Decay

Transitions must never mutate the input state.

---

## 8. Immutability

Once a state is finalized:
- It cannot be changed
- It can only be referenced

New states are created by transition,
never by mutation.

---

## 9. Zoom Compatibility

The state model is defined at maximum resolution (Zoom 3).

Rules:
- Lower zoom states are aggregations
- Aggregations must be loss-aware
- Aggregations must be reversible in logic (not data)

Zoom does not alter the state,
only how it is observed.

---

## 10. Storage Constraints

States may be stored as:
- Full snapshots
- Delta-encoded differences
- Hybrid models

Storage format does not change semantics.

---

## 11. Auditing and Replay

States must support:
- Hashing
- Comparison
- Replay verification

If a replayed state diverges from stored state,
the system must flag inconsistency.

---

## 12. Failure Semantics

If a state fails validation:
- It must not be published
- It must not be replayed
- It must not be used for aggregation

Failure must be explicit, never silent.

---

## 13. Canonical Rule

If the state is ambiguous,
the implementation is wrong.

SolumWorld does not guess.
It defines.
