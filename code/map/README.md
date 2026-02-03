# 🗺️ Map (Legacy) — SolumView Rendering Layer

Purpose:

- SolumMap / SolumView **rendering layer**
- **Pure visualization**
- Deterministic, reproducible output

This folder currently uses the legacy name **`map`**.
It will be renamed to **`solumview`** once the module boundaries are fully stable.

The name is temporary.
The role is canonical.

---

## ✅ What this module IS

This module is the **visual endpoint** of the Zipvilization stack.

It renders **already-processed** and **already-interpreted** world state into a visible form:
- territories
- world surfaces
- zoom-level framing
- UI presentation (later)
- evolution/timeline views (later)

This layer does not decide meaning.
It renders meaning that is defined upstream.

---

## 🔗 Where the inputs come from (canonical layering)

This module is the **final consumer** of outputs produced by higher technical layers:

- **Solumtools** (signals)
  - Extracts verifiable on-chain data
  - Produces normalized metrics and schemas

- **SolumWorld** (world state)
  - Converts signals into coherent world state
  - Defines zoom logic, state transitions, evolution rules, invariants

- **SolumView** (this module)
  - Renders SolumWorld state into visual output
  - No interpretation, no policy, no chain reads

In short:

> Solumtools observes → SolumWorld defines → SolumView renders

---

## 🔒 Constraints (non-negotiable)

- **No chain access**
  - No RPC calls
  - No contract reads
  - No event indexing

- **No business interpretation**
  - No market logic
  - No analytics decisions
  - No “meaning” generation

- **Render-only**
  - Input must be a deterministic data object (schemas defined upstream)
  - Output must be reproducible from the same input

Correctness here means:

> same input → same output

---

## 📦 Current state

This folder is intentionally minimal.

- `stub.ts` exists as a placeholder for the rendering entrypoint.
- The real rendering pipeline will be added **only after**:
  - Solumtools output schemas are stable
  - SolumWorld state model and zoom rules are stable

```0
