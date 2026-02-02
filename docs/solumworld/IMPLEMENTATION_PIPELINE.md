# SolumWorld — Implementation Pipeline

Version: alpha-pipeline v0.1  
Status: Technical / Execution  
Scope: From chain data to world representation

---

## 1. Purpose of This Document

This document explains **how SolumWorld is built**, not what it represents.

It defines the execution pipeline that converts:
- on-chain Solum state
into
- deterministic, multi-zoom world data.

This pipeline is mandatory for any SolumWorld implementation.

---

## 2. High-Level Pipeline Overview

SolumWorld is constructed through five sequential phases:

1. Indexing
2. Snapshotting
3. Spatial Mapping
4. Zoom Aggregation
5. Rendering Preparation

Each phase:
- consumes structured input,
- produces deterministic output,
- is independently testable.

---

## 3. Phase 1 — Indexing

### 3.1 Objective

Extract all Solum-relevant on-chain data.

### 3.2 Inputs

- Solum contract address
- Chain RPC endpoint
- Start block (deployment block)

### 3.3 Indexed Data

Minimum required:
- Transfer events
- Balance changes per address
- Total supply changes (burns)

Optional:
- Treasury transfers
- Liquidity-related events

### 3.4 Output

A normalized event database:

- address
- block number
- tx hash
- delta balance
- timestamp

Indexing must be:
- append-only
- reproducible
- independent of rendering logic

---

## 4. Phase 2 — Snapshotting

### 4.1 Objective

Create discrete world states over time.

### 4.2 Snapshot Triggers

Snapshots may be created:
- at fixed block intervals
- on significant events (e.g. supply change)
- on demand (historical query)

### 4.3 Snapshot Contents

Each snapshot includes:
- block number
- timestamp
- balances per address
- total supply
- version metadata

Snapshots are immutable once created.

---

## 5. Phase 3 — Spatial Mapping

### 5.1 Objective

Convert balances into land parcels.

### 5.2 Mapping Rules

- 1 Solum = 1 m²
- Parcels must be contiguous in Wallet Mode
- Assignment must be deterministic

### 5.3 Determinism Requirements

Parcel mapping must depend only on:
- snapshot data
- mapping algorithm version
- global seed (if used)

No randomness without seed.
No manual overrides.

### 5.4 Output

For each snapshot:
- parcel geometry per address
- total mapped area
- unassigned / reserve area (if any)

---

## 6. Phase 4 — Zoom Aggregation

### 6.1 Objective

Generate world representations for each zoom level.

### 6.2 Zoom Processing

Each zoom level is derived from the same base mapping:

- Zoom 0: global aggregation
- Zoom 1: regional aggregation
- Zoom 2: district aggregation
- Zoom 3: local aggregation
- Max Zoom: parcel close-up (wallet mode only)

Lower zooms must never require higher zoom data.

### 6.3 Output

For each zoom:
- tile data
- aggregated ownership metrics
- spatial indices

---

## 7. Phase 5 — Rendering Preparation

### 7.1 Objective

Prepare data for visualization engines.

### 7.2 Responsibilities

This phase:
- converts geometry into renderable primitives
- attaches metadata (labels, metrics)
- preserves separation between truth and representation

### 7.3 Non-Responsibilities

This phase does NOT:
- choose visual style
- simulate gameplay
- add narrative content

---

## 8. Wallet Mode Pipeline

Wallet Mode is a filtered execution of the same pipeline:

- Single address focus
- Contiguous parcel extraction
- Max zoom enabled
- No global aggregation

Wallet Mode must still be deterministic and reproducible.

---

## 9. Evolution Mode Pipeline

Evolution Mode replays the pipeline across snapshots:

- Snapshot N → world state
- Snapshot N+1 → updated world state

Differences between snapshots are:
- derived, not stored manually
- auditable

---

## 10. Versioning Strategy

Each phase may evolve independently.

Any change to:
- mapping logic
- zoom aggregation
- snapshot schema

must:
- increment pipeline version
- document migration behavior

---

## 11. Failure Isolation

If a phase fails:
- previous outputs remain valid
- no partial world state is published

---

## 12. Summary

SolumWorld is not a renderer.
It is a **deterministic world compiler**.

This pipeline defines how raw blockchain data becomes a structured, navigable world without ambiguity or manual intervention.

---

End of document.
