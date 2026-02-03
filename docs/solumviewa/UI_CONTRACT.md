# SolumView — UI Contract (Canonical)

## Purpose

This document defines the **canonical UI contract** for SolumView.

UI in Zipvilization is not presentation-first.
It is **state-first**.

The UI layer exists solely to expose SolumWorld state in a deterministic,
auditable and reproducible way.

---

## Core UI Principle

> The UI must never add meaning. It may only reveal meaning that already exists.

UI is not allowed to:
- infer
- optimize
- simplify away state
- hide contradictions

---

## UI Scope

The UI layer is responsible for:
- rendering state
- enabling navigation
- switching perspective (zoom, wallet, time)

The UI layer is **not responsible** for:
- computing state
- validating state
- resolving conflicts
- applying rules

---

## Deterministic Rendering

For the same inputs:
- SolumWorld state
- zoom level
- timestamp
- wallet context

The UI output **must be identical**.

This applies to:
- layout
- visible elements
- icons
- ordering
- emphasis rules

---

## UI Inputs (Authoritative)

UI may only depend on:
- canonical SolumWorld data
- canonical SolumView rules
- explicit user actions

UI must not depend on:
- client heuristics
- user history
- device characteristics
- network conditions (beyond availability)

---

## UI Actions

UI actions are limited to:

- change zoom
- change time / evolution step
- change wallet context
- toggle view modes

Actions must:
- be explicit
- be reversible
- never mutate state

---

## Wallet Mode (UI Perspective)

Wallet mode is a **lens**, not a filter.

Wallet mode may:
- highlight owned elements
- surface ownership metadata
- improve navigation relevance

Wallet mode must not:
- hide non-owned state
- reorder reality
- collapse global context

---

## UI and Zoom Interaction

Zoom defines:
- information density
- allowed UI elements
- interaction granularity

Rules:
- Lower zoom = less detail, never less truth
- Higher zoom = more detail, never more meaning

UI must not allow interactions forbidden by the current zoom.

---

## UI and Evolution Mode

Evolution mode modifies **temporal perspective only**.

UI must:
- clearly separate present vs historical
- never blend timelines
- never animate speculative transitions

All evolution steps are discrete and explicit.

---

## Error Handling in UI

Errors must be:
- explicit
- visible
- state-linked

UI must never:
- silently fail
- auto-correct state
- guess user intent

---

## Forbidden UI Patterns

UI must never:
- gamify ownership
- rank parcels or wallets
- imply value or performance
- hide uncertainty behind visuals

If a UI element requires explanation to avoid misinterpretation,
it violates this contract.

---

## AI Compatibility Clause

The UI must be interpretable by AI systems without:
- visual guessing
- context outside the repo
- training-specific heuristics

UI structure must be machine-readable and logically reversible.

---

## Canonical Status

This document defines the **only valid UI behavior** for SolumView.

Any UI implementation that diverges from this contract
is non-canonical by definition.
