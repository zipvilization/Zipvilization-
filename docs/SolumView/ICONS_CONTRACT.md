# SolumView — Icons Contract (Canonical)

## Purpose

This document defines the **canonical contract for icons** used in SolumView.

Icons are not UI assets.
They are **semantic state encoders**.

Every icon represents **exactly one meaning**, derived from SolumWorld state.

---

## Core Principle

> An icon may only represent information that already exists on-chain or in canonical SolumWorld state.

Icons must never:
- speculate
- predict
- embellish
- imply hidden attributes

---

## Icon Categories

Icons are grouped by **semantic role**, not by style.

### 1. Ownership Icons

Represent wallet-level ownership relationships.

Examples:
- owned parcel
- externally owned parcel
- unowned / neutral parcel

Rules:
- Ownership icons depend strictly on resolved state + wallet mode
- No ownership icon may appear before ownership exists at that zoom

---

### 2. State Icons

Represent internal parcel or region state.

Examples:
- active
- inactive
- transitioning
- locked / frozen

Rules:
- State icons must match `STATE_MODEL`
- Transitional states must be explicit (no ambiguity)

---

### 3. Evolution / Timeline Icons

Represent temporal context.

Examples:
- genesis marker
- changed-in-this-step
- historical snapshot indicator

Rules:
- These icons depend on time resolution, not zoom
- They must never alter perceived current state

---

### 4. Validation / Determinism Icons

Represent verification and reproducibility.

Examples:
- deterministic state confirmed
- divergence detected
- validation failed

Rules:
- These icons are informational only
- They do not modify behavior or permissions

---

## Icon Determinism Rules

For a given:
- SolumWorld state
- timestamp / block
- zoom level
- wallet context

The icon set **must be identical** across:
- clients
- devices
- sessions
- AI agents

No randomness.
No client-side inference.

---

## Icon + Zoom Interaction

Zoom determines **which icons may appear**.

Rules:
- ZOOM 0–1: aggregate icons only
- ZOOM 2: ownership + state icons allowed
- ZOOM 3: full icon set allowed

Icons forbidden at a zoom level must not render, even if data exists deeper.

---

## Icon + Wallet Mode

Wallet mode only affects:
- emphasis
- highlighting
- contrast

Wallet mode must never:
- hide other icons
- remove state visibility
- create private-only symbols

---

## Forbidden Icon Behaviors

Icons must never:
- encode probabilities
- encode future states
- imply value, yield or ranking
- substitute text-based validation

If an icon requires explanation, it is invalid.

---

## AI Safety Clause

Icons are designed to be:
- machine-readable
- unambiguous
- reversible to state

Any AI interpreting SolumView must be able to:
- map icon → state
- map state → icon

Without heuristics.

---

## Canonical Guarantee

Icons are part of the **visual consensus layer**.

Breaking this contract breaks:
- determinism
- reproducibility
- auditability

This file is canonical and supersedes any UI implementation detail.
