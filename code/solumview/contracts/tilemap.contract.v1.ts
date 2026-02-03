/**
 * Zipvilization — SolumView
 * TileMap Contract v1 (CANONICAL)
 *
 * This contract defines the deterministic shape of a TileMap used by SolumView.
 * It is intentionally strict and storage-agnostic.
 *
 * If a field is not defined here, it does not exist.
 */

export const TILEMAP_CONTRACT_V1 = {
  meta: {
    contract_id: "solumview.tilemap.contract.v1",
    version: 1,
    status: "alpha",
    scope: "solumview",
    canonical: true,
    notes: [
      "Defines the deterministic grid representation used by SolumView.",
      "Storage-agnostic: does not dictate where data is stored.",
      "Designed to compose across zoom levels via chunking."
    ]
  },

  /**
   * Coordinate system
   * - origin: (0,0) is the deterministic anchor for the selected view scope
   * - axes: x increases east/right, y increases south/down (screen-friendly)
   * - units: tiles (not meters). The meter->tile mapping is defined by ZoomRules.
   */
  coordinate_system: {
    origin: "top_left",
    axis: { x: "east", y: "south" },
    unit: "tile"
  },

  /**
   * Chunking
   * - The world is represented as chunks of fixed size.
   * - A TileMap payload may include one or many chunks.
   * - Chunk IDs must be deterministic, reproducible, and stable.
   */
  chunking: {
    chunk_size_tiles: 64,
    chunk_id_rule: "chunk:{cx}:{cy}",
    tile_id_rule: "tile:{x}:{y}"
  },

  /**
   * Tile types
   * - A tile is a single cell in the grid.
   * - tile.type is the minimal semantic needed by SolumView.
   * - Rendering is handled by UI/icon mappings elsewhere, but type is canonical here.
   *
   * IMPORTANT:
   * - Do not invent new tile types without updating this contract.
   */
  tile_types: [
    "void",          // outside of current view bounds
    "arid",          // moment-0 baseline soil (pre-civilization)
    "soil",          // habitable land
    "fertile",       // enhanced land (post-activity / evolution)
    "water",         // permanent geography
    "forest",        // permanent geography
    "mountain",      // permanent geography
    "path",          // movement trace / infrastructure
    "farm",          // human-readable land use
    "settlement",    // village/city marker
    "structure"      // reserved for deterministic structures
  ],

  /**
   * Tile object schema
   * - Minimal canonical tile representation.
   * - Optional fields must remain optional across versions.
   */
  tile_schema: {
    required: ["x", "y", "type"],
    properties: {
      x: { type: "integer", min: 0 },
      y: { type: "integer", min: 0 },
      type: { type: "enum", values: "tile_types" },

      // Optional deterministic attributes (no free text)
      elevation: { type: "integer", min: 0, optional: true }, // rendering hint only
      fertility: { type: "integer", min: 0, max: 100, optional: true }, // rendering hint only

      // Optional provenance references (strict identifiers only)
      provenance: {
        type: "object",
        optional: true,
        properties: {
          source: {
            type: "enum",
            values: ["derived", "onchain", "snapshot"]
          },
          source_ref: { type: "string", optional: true } // e.g., block:xxxx / snapshot_id:...
        }
      }
    }
  },

  /**
   * Chunk payload schema
   * - A chunk includes bounds and tile data.
   * - tiles can be dense or sparse:
   *   - dense: full list (chunk_size^2)
   *   - sparse: only non-default tiles (default implied by "default_tile_type")
   */
  chunk_schema: {
    required: ["chunk_id", "cx", "cy", "bounds", "default_tile_type", "tiles"],
    properties: {
      chunk_id: { type: "string", pattern: "^chunk:-?\\d+:-?\\d+$" },
      cx: { type: "integer" }, // chunk coordinate x
      cy: { type: "integer" }, // chunk coordinate y
      bounds: {
        type: "object",
        required: ["x0", "y0", "x1", "y1"],
        properties: {
          x0: { type: "integer" },
          y0: { type: "integer" },
          x1: { type: "integer" }, // inclusive
          y1: { type: "integer" }  // inclusive
        }
      },
      default_tile_type: { type: "enum", values: "tile_types" },
      tiles: { type: "array", items: "tile_schema" }
    }
  },

  /**
   * TileMap payload (top-level)
   * - Represents a set of chunks for a given view scope and moment in time.
   */
  payload_schema: {
    required: ["contract_id", "view", "moment", "chunks"],
    properties: {
      contract_id: { type: "string", const: "solumview.tilemap.contract.v1" },

      view: {
        type: "object",
        required: ["scope", "zoom_level"],
        properties: {
          scope: {
            type: "enum",
            values: ["world", "territory", "wallet"]
          },
          zoom_level: {
            type: "integer",
            min: 0,
            description: "Zoom 0 is the world view. Higher numbers zoom in."
          },

          // Optional: used for wallet mode / territory mode anchoring
          wallet_address: { type: "string", optional: true },
          territory_id: { type: "string", optional: true }
        }
      },

      moment: {
        type: "object",
        required: ["mode"],
        properties: {
          mode: {
            type: "enum",
            values: ["moment0", "current", "historical"]
          },
          // Used only when mode === "historical"
          timestamp: { type: "integer", optional: true },
          block_number: { type: "integer", optional: true }
        }
      },

      chunks: { type: "array", items: "chunk_schema" }
    }
  },

  /**
   * Determinism constraints (MUST)
   */
  determinism: {
    must: [
      "Tile IDs and chunk IDs must be reproducible from coordinates.",
      "No random generation is allowed at render time.",
      "Any evolution from moment0 must be derived from explicit state rules (Evolution Contract).",
      "If data is missing, represent it explicitly (e.g., void/arid), do not hallucinate."
    ]
  }
} as const;

export type TileMapContractV1 = typeof TILEMAP_CONTRACT_V1;
