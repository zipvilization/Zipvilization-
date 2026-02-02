# SolumWorld — State Canon

## Purpose

This document defines the **canonical state system** of SolumWorld.

State is the ultimate source of truth.
If something is not representable, derivable, or valid under this state system,
it does not exist in SolumWorld — regardless of visuals, simulations, or narratives.

This module is **implementation-agnostic** and **engine-independent**.

---

## What “State” Means in SolumWorld

State is the complete, minimal, and auditable description of:

- what exists
- where it exists
- in which condition it exists
- how it may change
- what must never change

State is **not**:
- a rendering
- a UI
- a gameplay mechanic
- an optimization
- a convenience abstraction

State **precedes** all of those.

---

## Authority Model

The state system has **absolute authority**.

Any layer consuming state (engine, AI, simulation, visualization, tooling)
must adapt to state — never the other way around.

No external system may:
- bypass state rules
- mutate state without validation
- invent state outside this model

---

## Canonical Guarantees

The state system guarantees:

- determinism at the state level
- auditability across time
- replayability of world evolution
- rollback capability without ambiguity
- invariants that cannot be violated

If a future implementation cannot satisfy these guarantees,
it is considered invalid.

---

## Module Structure

This folder defines the complete state model through the following documents:

- **STATE_INVARIANTS**  
  Rules that must always hold true. They define the identity of the world.

- **STATE_TRANSITIONS**  
  The only allowed ways state may change.

- **STATE_VALIDATION**  
  How state correctness is checked and enforced.

- **STATE_HISTORY**  
  How past states are recorded, referenced, and replayed.

- **STATE_ROLLBACK**  
  Conditions and mechanisms for reverting state safely.

Each document addresses a single responsibility.
Together they form a closed, coherent system.

---

## Relationship to Time and Evolution

State is not static.

Evolution in SolumWorld is expressed as:
- a sequence of validated state transitions
- preserving invariants
- producing an auditable history

There is no concept of “current” without history.
There is no concept of “future” without valid transitions.

---

## Relationship to Other Modules

- **Zoom levels** interpret state at different resolutions.
- **Evolution rules** operate strictly through state transitions.
- **AI systems** observe and propose changes, but do not own state.
- **Visual layers** are projections, not authorities.

State is upstream of all of them.

---

## Final Rule

If there is ever a conflict between:
- documentation and implementation
- visualization and state
- simulation and invariants

**State wins. Always.**

This document is the reference point for all such conflicts.
