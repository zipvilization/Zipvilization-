OUTPUT_SCHEMAS — SolumTools (Canonical)

This document defines the canonical OUTPUT SCHEMAS produced by SolumTools.
It is intended for deterministic interpretation by humans and AI systems.

SolumTools is a TOOLING layer.
It does NOT invent data.
It transforms, aggregates, validates, and visualizes existing Solum / SolumWorld data.

All outputs must comply with these schemas.

--------------------------------------------------
GENERAL RULES
--------------------------------------------------

1. Outputs are READ-ONLY representations.
2. No output mutates on-chain state.
3. No output performs speculative inference.
4. All outputs are deterministic given the same inputs.
5. Every output must be reproducible.

--------------------------------------------------
SCHEMA FORMAT
--------------------------------------------------

Each schema is described using:
- NAME
- PURPOSE
- INPUTS
- OUTPUT STRUCTURE
- GUARANTEES
- FAILURE MODES

--------------------------------------------------
SCHEMA 1 — WALLET_VIEW
--------------------------------------------------

NAME:
WALLET_VIEW

PURPOSE:
Represent the state of a single wallet within SolumWorld and SolumView.

INPUTS:
- wallet_address
- block_height (optional)
- timestamp (optional)

OUTPUT STRUCTURE:
{
  wallet_address: address,
  solum_balance: uint256,
  solum_percent_supply: float,
  parcels_owned: uint256,
  parcels_visible: uint256,
  governance_weight: float,
  last_activity_block: uint256
}

GUARANTEES:
- Balance matches on-chain Solum balance at reference block.
- Percent supply derived from canonical total supply.
- No historical reconstruction unless explicitly requested.

FAILURE MODES:
- Wallet does not exist → empty but valid structure.
- Chain unavailable → explicit error state.

--------------------------------------------------
SCHEMA 2 — PARCEL_VIEW
--------------------------------------------------

NAME:
PARCEL_VIEW

PURPOSE:
Represent a land parcel or group of parcels at a given zoom level.

INPUTS:
- parcel_id
- zoom_level
- block_height

OUTPUT STRUCTURE:
{
  parcel_id: string,
  zoom_level: integer,
  surface_m2: uint256,
  owner_wallet: address,
  neighbors: [parcel_id],
  state_hash: bytes32
}

GUARANTEES:
- Parcel geometry derived from SolumWorld rules.
- Ownership resolved from canonical wallet state.

FAILURE MODES:
- Parcel not allocated yet → state = UNASSIGNED.

--------------------------------------------------
SCHEMA 3 — ZOOM_RENDER_STATE
--------------------------------------------------

NAME:
ZOOM_RENDER_STATE

PURPOSE:
Describe what must be rendered at a specific zoom level.

INPUTS:
- zoom_level
- reference_time

OUTPUT STRUCTURE:
{
  zoom_level: integer,
  visible_entities: [string],
  render_mode: enum,
  aggregation_rules: string
}

GUARANTEES:
- No UI decisions embedded.
- Rendering hints only, not visual assets.

--------------------------------------------------
SCHEMA 4 — EVOLUTION_SNAPSHOT
--------------------------------------------------

NAME:
EVOLUTION_SNAPSHOT

PURPOSE:
Capture SolumWorld state at a given moment for historical comparison.

INPUTS:
- timestamp
- block_height

OUTPUT STRUCTURE:
{
  timestamp: uint256,
  block_height: uint256,
  total_wallets: uint256,
  total_parcels: uint256,
  occupied_surface_m2: uint256,
  state_root_hash: bytes32
}

GUARANTEES:
- Snapshot is immutable once generated.
- Hash allows later verification.

--------------------------------------------------
SCHEMA 5 — CONSISTENCY_REPORT
--------------------------------------------------

NAME:
CONSISTENCY_REPORT

PURPOSE:
Validate internal coherence between Solum, SolumWorld and SolumView.

INPUTS:
- reference_block

OUTPUT STRUCTURE:
{
  reference_block: uint256,
  checks_passed: uint256,
  checks_failed: uint256,
  warnings: [string],
  fatal_errors: [string]
}

GUARANTEES:
- No silent failure.
- Any inconsistency is explicit.

--------------------------------------------------
FINAL NOTE
--------------------------------------------------

SolumTools outputs are CONTRACTS OF MEANING.
If an output does not match these schemas, it is INVALID by definition.
