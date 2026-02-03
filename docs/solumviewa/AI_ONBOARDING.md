AI_ONBOARDING — SolumView (Zipvilization)
=================================

Purpose
-------
This document defines how an AI system must read, interpret, and operate
with the SolumView specification.

SolumView is the FINAL visualization layer of Zipvilization.
It is not a simulation engine, not a game logic layer, and not an economic model.
It is a deterministic visual projection of already-defined state.

This document does NOT define new rules.
It defines how to correctly consume the existing ones.

Scope
-----
This onboarding applies ONLY to the folder:

docs/SolumView/

No other folders, abstractions, or inferred structures are allowed.

The current SolumView canon consists of the following files:

- README.md
- PIPELINE_CANON.md
- ZOOM_MAPPING.md
- ICONS_CONTRACT.md
- UI_CONTRACT.md
- WALLET_MODE.md
- VISUAL_DETERMINISM.md

An AI must assume:
- These files are complete
- These files are authoritative
- No missing pieces should be invented

What SolumView IS
-----------------
SolumView is a deterministic renderer.

Input:
- SolumWorld state (already validated elsewhere)
- Time (block / epoch / snapshot)
- Zoom level
- Optional wallet context

Output:
- A reproducible visual state

SolumView does NOT:
- Modify state
- Decide evolution
- Simulate behavior
- Apply randomness
- Apply artistic interpretation

What SolumView is NOT
--------------------
SolumView is NOT:
- A UI framework
- A game client
- A data source
- A logic engine
- A place to optimize UX freely

All freedom exists upstream.
SolumView only reflects.

How an AI must read the files (order matters)
---------------------------------------------

1. README.md
   - Defines SolumView’s role inside Zipvilization
   - Establishes visual philosophy and limits
   - This file sets hierarchy: everything else must align to it

2. PIPELINE_CANON.md
   - Defines the transformation pipeline:
     SolumWorld → Mapping → Icons → UI State → Render
   - No step may be skipped
   - No step may be reordered

3. ZOOM_MAPPING.md
   - Defines how SolumWorld zoom levels map to SolumView representations
   - Zoom is semantic, not just scale
   - An AI must never interpolate between zooms

4. ICONS_CONTRACT.md
   - Defines the visual alphabet
   - Icons are contracts, not assets
   - An icon has meaning, constraints, and invariants

5. UI_CONTRACT.md
   - Defines allowed UI states
   - Includes timeline and evolution presentation rules
   - No UI state outside this file is valid

6. WALLET_MODE.md
   - Defines wallet-centric visualization
   - Covers: search, inspect, connect wallet
   - Wallet mode changes perspective, not rules

7. VISUAL_DETERMINISM.md
   - Defines reproducibility guarantees
   - Same inputs MUST produce identical outputs
   - This is non-negotiable

Strict Rules for AI Systems
---------------------------

An AI working with SolumView MUST:

- Never invent files, folders, or layers
- Never introduce new zoom levels
- Never introduce new icons
- Never smooth, interpolate, or guess missing data
- Never “improve” UX outside the contract
- Never mix SolumWorld logic into SolumView
- Never apply randomness or stylistic variation

If information is missing:
- The correct action is to STOP
- Or to surface an explicit undefined state
- Not to infer or approximate

Wallet Mode Constraints
-----------------------
Wallet Mode is a VIEW MODE, not a feature mode.

It allows:
- Selecting a wallet
- Inspecting holdings
- Viewing SolumView through wallet ownership

It does NOT allow:
- Altering state
- Aggregating speculative data
- Predicting future states

Wallet Mode must respect:
- Zoom rules
- Icon contracts
- UI contracts
- Determinism

Evolution & Timeline
--------------------
Evolution is a PRESENTATION of past states.

SolumView may:
- Display historical snapshots
- Show transitions between validated states

SolumView may NOT:
- Simulate evolution
- Predict outcomes
- Compress time non-deterministically

Timeline views must be reversible and reproducible.

Common Errors to Avoid
----------------------
The following are considered critical violations:

- “Making it clearer”
- “Making it prettier”
- “Optimizing performance by approximation”
- “Adding helpful indicators”
- “Guessing user intent”
- “Filling gaps visually”

Silence or emptiness is preferable to invention.

Final Rule
----------
SolumView is a mirror.

If something is not explicitly defined upstream,
it must not appear downstream.

If two renders differ with the same input,
the system is broken.

End of document.
