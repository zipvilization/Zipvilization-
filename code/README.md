# Code Layer

This directory contains the **technical components** of Zipvilization.

Everything here is **Phase 0 / Chapter 0** unless explicitly stated otherwise.

If something is not present in `code/`, it does not exist operationally.

---

## Purpose

The Code Layer exists to:

- implement or prototype **execution primitives**
- define **deterministic boundaries** between on-chain data and readable world state
- provide tooling for **observation, indexing, and interpretation**
- make Zipvilization reproducible for auditors (human + AI)

It does **not** exist to:
- optimize outcomes
- enforce narratives
- guarantee behavior
- protect participants from market risk

---

## Current State (Chapter 0)

At this stage:

- components are **scaffolding**
- some parts are **stubs by design**
- nothing should be interpreted as “live” unless explicitly marked

This repository reflects **work in progress**, not a deployed system.

---

## Repository Structure (Actual)

These are the current Phase 0 anchors in this repo:

- `indexer/`  
  Off-chain ingestion / indexing scaffolding.  
  Reads on-chain events and produces reproducible, queryable data surfaces.

- `world/`  
  SolumWorld execution scaffolding.  
  Deterministic rules for converting raw signals → coherent world state.

- `map/` *(temporary name)*  
  SolumView scaffolding (visual / UX layer).  
  **Planned rename:** `map/` → `solumview/` once the folder contains multiple canonical files.

- `shared/`  
  Shared types, contracts, schemas, and boundary definitions used across layers.

If a folder is not listed here, assume it is not part of the current Phase 0 plan.

---

## On-chain Components

Smart contracts (when present in `code/`):

- are not deployed by default
- have no authority until deployed
- may change during Chapter 0

No assumptions should be made based solely on the presence of code.

---

## Testing and Automation

CI, tests, and automation may exist in incomplete form.

They are used internally to:
- validate assumptions
- detect inconsistencies
- explore failure modes

They do not imply guarantees of correctness.

---

## Final Note

Zipvilization is not defined by code alone.

Code is necessary, but not a promise.

If a component becomes canonical, it will be clearly documented as such.
Until then, read this directory as:

**experimentation in public, without commitment**.
```0
