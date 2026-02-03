# SolumView — Zoom Mapping Canon

## Purpose

This document defines the **canonical mapping** between
**SolumWorld zoom levels** and **SolumView visual zooms**.

Zoom in SolumView is **not a camera trick**.
It is a **semantic resolution selector**.

Zoom determines *what can be seen*, not *how close it looks*.

---

## Fundamental Rule

> SolumView never invents detail.

If information is not present in SolumWorld at a given zoom,
it **must not appear** in SolumView.

---

## Zoom Concepts

### SolumWorld Zoom
- Logical / structural resolution
- Defines how land, ownership and state are grouped
- Canonical and deterministic

### SolumView Zoom
- Visual resolution
- Reveals subsets of SolumWorld state
- Purely representational

SolumView zooms are **derived**, never independent.

---

## Canonical Zoom Levels

The following mapping is canonical and exhaustive.

### ZOOM 0 — World / Civilization

**SolumWorld**
- Entire world aggregation
- No individual ownership
- Macro state only

**SolumView**
- World-scale view
- Global patterns
- No parcels, no wallets

**Use cases**
- Civilization overview
- Global evolution playback

---

### ZOOM 1 — Regions / Territories

**SolumWorld**
- Large territorial groupings
- Still abstracted ownership

**SolumView**
- Regions become visible
- Borders and large clusters appear
- No individual parcels

**Use cases**
- Expansion patterns
- Territorial evolution

---

### ZOOM 2 — Parcels / Colonies

**SolumWorld**
- Discrete land units
- Ownership becomes explicit

**SolumView**
- Individual parcels rendered
- Wallet-linked highlighting enabled
- Structural state visible

**Use cases**
- Ownership analysis
- Wallet mode primary entry

---

### ZOOM 3 — Local / Microstate

**SolumWorld**
- Fine-grained state
- Local attributes and flags

**SolumView**
- Detailed parcel internals
- Microstate overlays
- No speculative detail

**Use cases**
- Inspection
- Validation
- Forensic analysis

---

## Zoom Transition Rules

- Zoom transitions are **discrete**
- No interpolation between zooms
- No partial states

Switching zoom always triggers:
1. Re-resolution of state
2. Re-normalization
3. Full re-render

---

## Zoom + Time (Evolution Mode)

Zoom and time are orthogonal:

- Time is resolved first
- Zoom is resolved second

This guarantees that:
- Historical zooms are accurate
- Past detail is not retroactively invented

---

## Zoom + Wallet Mode

Wallet mode does **not change zoom semantics**.

Rules:
- Zoom defines what exists
- Wallet mode defines what is highlighted

At any zoom:
- Non-owned land still exists
- Owned land is emphasized, not isolated

---

## Invalid Zoom States

SolumView must reject:
- Undefined zoom levels
- Fractional zooms
- Client-defined zoom semantics

If a zoom level is not specified here,
it does not exist.

---

## Canonical Guarantee

Given:
- the same SolumWorld state
- the same timestamp/block
- the same zoom level

SolumView **must always render the same output**.

Zoom is a contract, not a preference.

---

## Relationship to Other Canons

- PIPELINE_CANON defines *when* zoom is resolved
- ZOOM_MAPPING defines *what* zoom means
- ICONS and UI define *how* zoom is expressed

No document may override this mapping.
