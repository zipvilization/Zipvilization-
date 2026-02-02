# SolumWorld — Zoom Rules (Canonical Spec)

## 1. Purpose

This document defines how SolumWorld operates across zoom levels.

Zooms are not different worlds, modes, or layers.
They are different representations of the same underlying reality.

These rules guarantee coherence, determinism, and auditability
across all zoom levels.

---

## 2. Core Zoom Principles

1. Single Reality  
   There is only one SolumWorld state.
   Zooms are views, not forks.

2. No Duplication  
   Data exists canonically at exactly one zoom level.
   Other zooms derive their state from aggregation.

3. Deterministic Aggregation  
   Given the same lower-level data, higher-level zooms
   always compute the same state.

4. Controlled Information Loss  
   Moving up a zoom may lose detail,
   but never invents information.

5. Reversible Semantics (where possible)  
   Zooming in restores detail from canonical sources,
   not from approximations.

---

## 3. Canonical Simulation Zoom

### Zoom 3 — Parcel Level (Source of Truth)

Zoom 3 is the only level where:
- Individual Zips exist
- Production cycles are executed
- Resources are consumed or produced
- Structures operate with full detail

Rules:
- All economic and biological simulation happens here
- No simulation logic is allowed in higher zooms
- All higher zooms depend on Zoom 3 data

---

## 4. Aggregation Rules (Zooming Out)

### 4.1 Zoom 3 → Zoom 2

Aggregation inputs:
- Parcel production
- Zip populations
- Resource balances
- Structure states

Aggregation outputs:
- Total production per zone
- Population counts
- Activity indexes
- Zone classification

Lost information:
- Individual Zip identity
- Parcel-level timing details

---

### 4.2 Zoom 2 → Zoom 1

Aggregation outputs:
- Regional production profiles
- Dominant activities
- Infrastructure level indicators
- Stability metrics

Lost information:
- Individual zone layouts
- Specific structure types

---

### 4.3 Zoom 1 → Zoom 0

Aggregation outputs:
- Macro resource distributions
- Biome-level activity intensity
- Population estimates
- Strategic relevance indicators

Lost information:
- All settlement-level structure
- Production timing

---

## 5. Disaggregation Rules (Zooming In)

Zooming in never invents data.

Rules:
- Zoom-in restores data from canonical lower zooms
- Cached aggregates may be discarded at any time
- If lower-level data is missing, zoom-in fails gracefully

Zooming in order:
Zoom 0 → Zoom 1 → Zoom 2 → Zoom 3

Direct jumps are not allowed unless all intermediate data exists.

---

## 6. Temporal Consistency

Zooms must represent the same timestamp.

Rules:
- A zoom change does not advance time
- Aggregation always references the same snapshot
- Historical zooms must use historical snapshots

Violation example:
Showing Zoom 0 at epoch N and Zoom 3 at epoch N+1 is invalid.

---

## 7. Evolution Mode Interaction

In Evolution Mode:
- Zooms represent historical states
- Aggregation rules remain identical
- No retroactive mutation is allowed

Evolution playback must:
- Respect zoom rules
- Preserve information loss semantics
- Allow deterministic replay

---

## 8. Performance and Caching (Non-Canonical)

Caching is allowed but never canonical.

Rules:
- Cached zoom data must be invalidatable
- Cache misses must recompute from source
- Cached data must never mutate source data

---

## 9. Error Handling

If aggregation fails:
- Higher zoom must signal "unknown state"
- Never fabricate fallback values

If disaggregation fails:
- Zoom-in is blocked
- System must explain missing data

---

## 10. Canonical Rule

If two zoom levels contradict each other,
the lower zoom (closer to Zoom 3) is correct.

If Zoom 3 contradicts history,
the snapshot system is broken.

---

## 11. Final Constraint

Any engine, UI, AI, or simulation that does not respect
these zoom rules is not a valid SolumWorld implementation.
