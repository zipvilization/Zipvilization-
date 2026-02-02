# SolumWorld — Data Model (Canonical Spec)

## 1. Purpose of the Data Model

This document defines all canonical data entities of SolumWorld and their relationships.

It does not describe UI, rendering engines, blockchains, or implementation details.
It defines what exists, which properties it has, how entities relate to each other,
and which invariants must always hold.

Any implementation (frontend, backend, indexer, simulation engine, or AI)
must conform to this model.

If something is not defined here, it does not exist in SolumWorld.

---

## 2. Core Principles

1. Zoom-based scalability  
   A single reality represented at different levels of detail.
   Data is aggregated or disaggregated, never duplicated.

2. Determinism  
   Same state + same time always produces the same outcome.

3. Historical persistence  
   Past states are never overwritten.
   Evolution is a sequence of immutable states.

4. Technology neutrality  
   The model assumes no specific engine, language, database, or blockchain.

---

## 3. Root Entities

### 3.1 SolumWorld

Represents the entire SolumWorld universe at a given moment or across time.

Fields:
- world_id
- genesis_timestamp
- current_timestamp
- current_epoch
- current_zoom
- ruleset_version
- map_root_id

Invariants:
- Only one active SolumWorld exists per context
- Time never moves backwards in the active state

---

### 3.2 MapRoot

Entry point to the complete territorial structure.

Fields:
- map_root_id
- total_area (logical square meters)
- zoom_levels_available
- children[] (Zoom 0 territories)

---

## 4. Territorial Entities

### 4.1 Territory (abstract)

Common base entity for all zoom levels.

Fields:
- territory_id
- parent_id
- zoom_level
- area
- position
- created_at
- last_updated_at

Invariants:
- A territory has exactly one parent
- Children total area cannot exceed parent area

---

### 4.2 Zoom 0 — MacroTerritory

Represents continents or macro regions.

Fields:
- biome_type
- climate_profile
- resource_distribution (aggregated)
- population_estimate
- activity_index

---

### 4.3 Zoom 1 — Region

Represents large functional regions.

Fields:
- dominant_activity
- settlement_density
- infrastructure_level

---

### 4.4 Zoom 2 — Zone / Settlement

Represents towns, districts, or agricultural areas.

Fields:
- zone_type (agricultural / urban / mixed)
- active_structures[]
- zip_population

---

### 4.5 Zoom 3 — Parcel (Canonical Unit)

Smallest meaningful unit.

Fields:
- parcel_id
- owner_reference
- parcel_type
- production_state
- structures[]
- zip_units[]

Invariants:
- Parcels are indivisible
- Fine-grained simulation happens only here

---

## 5. Life Entities (Zips)

### 5.1 ZipUnit

Base unit of Zip civilization.

Fields:
- zip_id
- birth_timestamp
- current_location (parcel_id)
- role
- skill_set
- status

Rules:
- Zips never speak
- No direct UI exposure
- Actions are rule-driven only

---

## 6. Structures and Production

### 6.1 Structure

Fields:
- structure_id
- structure_type
- build_timestamp
- state
- efficiency
- maintenance_cost

---

### 6.2 ProductionNode

Fields:
- input_resources
- output_resources
- cycle_time
- assigned_zips[]

---

## 7. Resources

### 7.1 Resource

Fields:
- resource_type
- quantity
- quality
- renewable

---

## 8. Time and Evolution

### 8.1 WorldStateSnapshot

Fields:
- snapshot_id
- timestamp
- epoch
- hash
- diff_from_previous

Used for:
- Evolution mode
- Historical replay
- Auditing and verification

---

## 9. Relationship Overview

SolumWorld  
└─ MapRoot  
   └─ MacroTerritory (Z0)  
      └─ Region (Z1)  
         └─ Zone (Z2)  
            └─ Parcel (Z3)  
               ├─ Structure  
               ├─ ProductionNode  
               └─ ZipUnit  

---

## 10. Out of Scope

This document does not define:
- UI or rendering
- Visual assets
- Blockchain mechanics
- Monetary systems
- Human decision layers

Those belong to other specifications.

---

## 11. Canonical Rule

If an implementation contradicts this Data Model,
the implementation is wrong.
