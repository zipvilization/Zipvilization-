/**
 * Zipvilization — SolumView
 * Zoom Contract v1 (CANONICAL)
 *
 * Defines deterministic zoom semantics: Zoom 0 (world) and deeper zoom levels.
 * This is a rules contract: it does not render, it defines how rendering must be derived.
 *
 * If a rule is not defined here, it does not exist.
 */

export const ZOOM_CONTRACT_V1 = {
  meta: {
    contract_id: "solumview.zoom.contract.v1",
    version: 1,
    status: "alpha",
    scope: "solumview",
    canonical: true,
    notes: [
      "Zoom 0 is always the world view.",
      "All deeper zooms must be deterministic projections (no randomness).",
      "Meters→tiles mapping is defined per zoom level."
    ]
  },

  /**
   * Zoom levels
   * - Zoom 0: world projection (macro)
   * - Zoom 1+: increasingly localized views
   *
   * Important: the project can add more zoom levels later,
   * but only by updating this canonical contract.
   */
  zoom_levels: [
    {
      level: 0,
      name: "world",
      description:
        "Global world projection. Represents the whole world surface as a readable macro map."
    },
    {
      level: 1,
      name: "region",
      description:
        "Regional slice. Used to read large-scale geography and early civilization emergence."
    },
    {
      level: 2,
      name: "territory",
      description:
        "Territory framing. A colonist-facing view anchored on a territory/wallet."
    },
    {
      level: 3,
      name: "parcel",
      description:
        "Maximum practical zoom for readable local activity (farms/paths/settlement details)."
    }
  ],

  /**
   * View scopes
   * - world: global view (Zoom 0 default)
   * - wallet: user selects or connects a wallet, view anchors on that territory
   * - territory: explicit territory ID (backend-defined mapping)
   */
  view_scopes: ["world", "wallet", "territory"],

  /**
   * Tile scale rules
   * Defines how many meters of territory correspond to 1 tile at each zoom level.
   *
   * This does NOT assert that Solum is meters in this file.
   * It only defines the projection rule for SolumView.
   *
   * Example:
   * - at zoom 0, 1 tile may represent very large area (macro).
   * - at zoom 3, 1 tile may represent near-human scale.
   */
  meters_per_tile: [
    { zoom: 0, meters_per_tile: 500_000 }, // macro: compress world for visibility
    { zoom: 1, meters_per_tile: 10_000 },  // regional: readable clusters
    { zoom: 2, meters_per_tile: 100 },     // territory: human-readable land blocks
    { zoom: 3, meters_per_tile: 1 }        // parcel: 1 tile ≈ 1 meter (max detail)
  ],

  /**
   * Chunk coverage rules
   * A SolumView payload is composed of chunks (TileMap contract).
   * This defines minimal requirements per zoom.
   */
  coverage: {
    // chunk size must match TileMap contract v1
    chunk_size_tiles: 64,

    // minimum chunks that should be present to consider the view meaningful
    min_chunks: [
      { zoom: 0, min: 16 }, // world should not be a tiny cutout
      { zoom: 1, min: 9 },
      { zoom: 2, min: 4 },
      { zoom: 3, min: 1 }
    ],

    // recommended chunk grid shape (best practice, not mandatory)
    recommended_chunk_grid: [
      { zoom: 0, grid: "4x4" },
      { zoom: 1, grid: "3x3" },
      { zoom: 2, grid: "2x2" },
      { zoom: 3, grid: "1x1" }
    ]
  },

  /**
   * Anchor rules (deterministic)
   *
   * - World anchor: fixed. Zoom 0 always centers on the canonical world origin.
   * - Wallet anchor: derived from wallet address and deterministic mapping.
   * - Territory anchor: derived from territory ID (backend-defined but must be stable).
   *
   * This contract does not define the mapping algorithm (that is SolumWorld/Tools work),
   * but it defines that the mapping must be:
   * - stable
   * - reproducible
   * - auditable
   */
  anchors: {
    world: {
      zoom: 0,
      anchor_type: "fixed",
      description:
        "Zoom 0 anchor is fixed. The world origin must not drift across builds."
    },

    wallet: {
      anchor_type: "derived",
      required_fields: ["wallet_address"],
      description:
        "Wallet mode anchor is derived deterministically from the wallet_address."
    },

    territory: {
      anchor_type: "derived",
      required_fields: ["territory_id"],
      description:
        "Territory anchor is derived deterministically from territory_id."
    }
  },

  /**
   * Output invariants (MUST)
   * These rules are enforced across all zoom levels.
   */
  invariants: {
    must: [
      "Zoom 0 is always world scope unless explicitly overridden for internal tooling.",
      "No procedural randomness at render time.",
      "Same inputs (scope+anchor+moment+zoom) must yield the same chunks and tiles.",
      "If data is missing, represent explicit absence (void/arid) rather than inventing tiles.",
      "Chunk IDs and tile IDs must remain stable for the same coordinates."
    ]
  },

  /**
   * Validation hints (for CI / tools)
   * - These checks are for automated verification.
   * - They are not UI behavior.
   */
  validation: {
    checks: [
      {
        id: "zoom-level-known",
        rule: "payload.view.zoom_level must match a defined zoom level"
      },
      {
        id: "scope-known",
        rule: "payload.view.scope must be one of view_scopes"
      },
      {
        id: "anchor-required",
        rule:
          "wallet scope requires wallet_address; territory scope requires territory_id"
      },
      {
        id: "coverage-min",
        rule: "payload.chunks.length must be >= min_chunks for that zoom level"
      }
    ]
  }
} as const;

export type ZoomContractV1 = typeof ZOOM_CONTRACT_V1;
