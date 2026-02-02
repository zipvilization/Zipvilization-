# SolumWorld — Technical Specification

Version: alpha-spec v0.1  
Status: Technical Spec (Zipvilization)  
Scope: World rendering, zoom system, evolution pipeline

---

## 1. What is SolumWorld

SolumWorld is the **world representation layer** of Zipvilization.

From a technical perspective, SolumWorld is responsible for:

- Interpreting Solum on-chain state as a finite, spatial world.
- Mapping token balances to land area using a fixed unit scale.
- Rendering that land at multiple zoom levels with strict rules.
- Reconstructing world state deterministically at any point in time.

SolumWorld does not manage:
- token economics,
- governance,
- AI behavior,
- or narrative systems.

It consumes **indexed Solum data** and produces **deterministic world views**.

---

## 2. Core Invariants

These rules are mandatory and enforced at all layers:

1. **Finite World**  
   The total Solum supply defines a finite world area.

2. **Unit Mapping**  
   1 Solum = 1 square meter (1 m²).

3. **Deterministic Mapping**  
   World state must be reproducible from:
   - chain,
   - contract address,
   - block range,
   - algorithm version.

4. **No Manual Overrides**  
   Ownership and land truth must never be edited manually.

---

## 3. System Inputs and Outputs

### 3.1 Inputs

SolumWorld consumes:

- Solum contract address
- Chain identifier
- Indexed transfer events
- Indexed balances per snapshot
- Configuration parameters (zoom definitions, seed, version)

### 3.2 Outputs

SolumWorld produces:

- World tiles per zoom level
- Parcel mappings per address
- Aggregated region data
- Evolution snapshots

Outputs are **pure functions of inputs + versioned algorithms**.

---

## 4. World Model

### 4.1 World Grid

The world is represented as a 2D surface.

Implementation may use:
- square tiles,
- hex tiles,
- quadtrees,
- chunked grids.

Choice of grid does not change semantics as long as invariants hold.

### 4.2 Parcel Definition

A parcel is defined as:

- Area = wallet Solum balance × 1 m²
- Mapped to contiguous land in Wallet Mode
- Deterministically assigned using a reproducible algorithm

Parcel assignment algorithms must be:
- deterministic,
- seeded,
- versioned,
- documented.

---

## 5. Zoom System

SolumWorld defines an explicit zoom stack.
Each zoom has a strict responsibility.

### Zoom 0 — Global View

- Represents the entire world.
- Shows aggregated ownership density only.
- No individual parcels.
- Abstract visualization.

### Zoom 1 — Regional View

- Shows large regions and macro zones.
- Aggregates parcels into region blocks.
- No parcel-level detail.

### Zoom 2 — District View

- Shows districts and clusters.
- Parcel groups may be visible.
- Colonists can locate their area, not exact land.

### Zoom 3 — Local / Settlement View

- Individual parcel boundaries visible.
- Local structure overlays allowed.
- Derived settlement patterns only.

### Max Zoom — Parcel Close-Up (Wallet Mode)

- Shows a fraction of a single parcel.
- View is fully filled with land (no void).
- Human-scale interpretation.
- Zips (if rendered) are subordinate to environment.

Rule: **A zoom level may not display information belonging to a higher-detail zoom.**

---

## 6. World Modes

### 6.1 World Mode

- Focused on civilization-scale comprehension.
- Aggregated, anonymized views.
- No wallet-specific detail.

### 6.2 Wallet Mode

- Focused on a single address.
- Renders contiguous parcel land.
- Allows maximum zoom.

---

## 7. Evolution Mode

Evolution Mode reconstructs SolumWorld across time.

### 7.1 Purpose

- Visualize world growth from genesis to present.
- Provide auditable historical reconstruction.

### 7.2 Snapshot Strategy

Minimum viable approach:

- Periodic snapshots every N blocks.
- Event-based snapshots on significant state changes.

Each snapshot includes:
- balances,
- parcel assignments,
- aggregated world tiles,
- version metadata.

### 7.3 Determinism

Given:
- same inputs,
- same snapshot block,
- same algorithm version,

SolumWorld must generate identical outputs.

---

## 8. Rendering Layers

SolumWorld distinguishes:

### 8.1 Truth Layers

- Parcel boundaries
- Area calculations
- Ownership aggregation
- Snapshot timestamps

### 8.2 Representational Layers

- Visual structures
- Terrain decoration
- Civilization overlays

Representational layers must never contradict truth layers.

---

## 9. Implementation Expectations

A compliant SolumWorld implementation must:

- Index Solum data independently.
- Version all algorithms affecting spatial mapping.
- Separate indexing, mapping, and rendering steps.
- Support regeneration from chain data alone.

---

## 10. Non-Goals

SolumWorld does not:

- Simulate economic behavior.
- Guarantee realism of visuals.
- Replace Solum contract logic.
- Enforce off-chain governance.

---

## 11. Versioning and Compatibility

Any change affecting:
- parcel assignment,
- snapshot schema,
- zoom semantics,

must bump the SolumWorld spec version and document migration rules.

---

End of specification.
