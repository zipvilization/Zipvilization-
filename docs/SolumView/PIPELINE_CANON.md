# SolumView — Canonical Rendering Pipeline

## Purpose

This document defines the **canonical rendering pipeline** of **SolumView**.

SolumView is the **final visualization layer** of Zipvilization.
It does not invent data, simulate state, or apply subjective interpretation.
Its sole function is to **transform verified SolumWorld state into a deterministic visual view**.

If something is visible in SolumView, it must be derivable from:
- on-chain Solum state
- indexed historical data
- explicitly defined transformation rules

---

## High-level Pipeline Overview

The SolumView pipeline follows a strict, ordered flow:

1. **Input Resolution**
2. **Context Resolution (Wallet / Global)**
3. **Temporal Resolution (Moment / Evolution)**
4. **Zoom Resolution**
5. **State Normalization**
6. **Visual Mapping**
7. **Final Render Output**

Each stage is **pure**, **deterministic**, and **side-effect free**.

---

## 1. Input Resolution

### Data Sources

SolumView may consume data from:

- Solum smart contracts (canonical state)
- Indexers / subgraphs (derived but reproducible)
- Historical snapshots (block-based or time-based)

All inputs must be:
- versioned
- timestamped or block-referenced
- reproducible by a third party

No mutable client-side state is allowed to affect output.

---

## 2. Context Resolution (Wallet Mode)

Before rendering, SolumView resolves **view context**.

Two canonical modes exist:

### Global Mode
- No wallet selected
- World-scale visualization
- Aggregated, anonymized data only

### Wallet Mode
- A specific wallet address is selected
- Can be:
  - connected wallet
  - manually searched wallet
- View is **filtered**, never altered

Wallet mode **does not change reality**.
It only changes *which subset of SolumWorld is highlighted*.

---

## 3. Temporal Resolution (Evolution Mode)

SolumView supports temporal navigation.

### Supported temporal contexts:
- **Moment 0** (genesis)
- Any past block / timestamp
- Current state
- Continuous evolution playback

The pipeline must resolve **exactly one temporal slice** before zoom logic.

Rules:
- No interpolation unless explicitly defined
- Past states must be reconstructible
- Future states are never rendered

---

## 4. Zoom Resolution

After time and context are fixed, SolumView resolves zoom level.

Zoom levels are **imported conceptually from SolumWorld**, but mapped to view-space.

Characteristics:
- Each zoom has a fixed semantic meaning
- Zoom does not invent detail
- Zoom only reveals what already exists at that resolution

Zoom resolution must occur **before visual styling**.

---

## 5. State Normalization

Raw SolumWorld data is normalized into **render-ready primitives**:

Examples:
- parcels
- clusters
- territories
- ownership sets
- state flags

Normalization rules:
- one-to-one mapping
- no aggregation without definition
- reversible where possible

This step produces a **pure state model** for rendering.

---

## 6. Visual Mapping

Normalized state is mapped to visual elements:

- geometry
- color
- icons
- overlays
- emphasis / focus

Rules:
- visual meaning must be documented
- same input → same output
- no randomness
- no client-side personalization

Icons, colors and symbols are governed by separate contracts.

---

## 7. Final Render Output

The final output is:

- deterministic
- reproducible
- auditable
- comparable across clients

Two users rendering the same:
- wallet
- block
- zoom
must see **identical results**.

SolumView is therefore:
- not a game
- not a simulation
- not an artistic layer

It is a **truthful lens** over SolumWorld.

---

## Canonical Guarantees

SolumView guarantees:

- No hidden logic
- No privileged views
- No off-chain authority
- No non-documented transformations

If it is not described in the pipeline,
**it must not exist in SolumView**.

---

## Relationship to Zipvilization

Zipvilization is the ecosystem.
SolumWorld defines reality.
SolumView makes that reality visible.

The pipeline is the **contract between truth and perception**.
