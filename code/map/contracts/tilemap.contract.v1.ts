// code/map/contracts/tilemap.contract.v1.ts
/**
 * Tilemap Contract v1 — Zipvilization
 * -----------------------------------
 * Purpose:
 * - Provide a canonical, dictionary-first spec for how SolumView/Map tile data is encoded.
 * - Enable deterministic rendering: identical input => identical output.
 *
 * Scope:
 * - This contract defines *data shape* and *semantic meaning* of tile codes.
 * - It does NOT define how the world evolves over time (SolumWorld).
 * - It does NOT define UI layout (SolumView UI docs), only tile interpretation constraints.
 *
 * Canon rules:
 * - If a tile code is not defined in the dictionary, it must be rejected (fail-closed).
 * - Layers must match the declared dimensions.
 * - Versioning is strict and explicit.
 */

export const TILEMAP_CONTRACT_V1 = {
  id: "zipvilization.tilemap.contract.v1",
  version: 1 as const,

  /**
   * Determinism primitives:
   * - A renderer must not invent tiles.
   * - Unknown codes are invalid.
   * - Dimensions must match exactly.
   */
  determinism: {
    failClosedUnknownCodes: true,
    requireExactDimensions: true,
    requireCanonicalLayerOrder: true,
  },

  /**
   * Canonical layer order.
   * Renderers may support additional layers later, but v1 is strict.
   */
  layers: ["ground", "fertility", "water", "paths", "structures", "units"] as const,

  /**
   * Encoding:
   * - Each layer is a flat array of tile codes with length = width * height.
   * - Indexing is row-major: idx = y * width + x.
   */
  encoding: {
    indexing: "row-major" as const,
    tileCodeType: "string" as const,
    allowRLE: false, // v1 keeps it simple; compression can be added in v2+
  },

  /**
   * Canonical tile dictionary (dictionary-first).
   * Codes are short strings to keep payloads small and human-auditable.
   *
   * IMPORTANT:
   * - Keep codes stable once published.
   * - Additive growth is allowed; destructive renames require a new contract version.
   */
  dictionary: {
    // ---- Ground / base terrain ----
    "G0": { family: "ground", label: "arid_soil", renderHint: "brown_dry" },
    "G1": { family: "ground", label: "soil", renderHint: "brown" },
    "G2": { family: "ground", label: "grass", renderHint: "green" },

    // ---- Fertility overlay (non-physical layer used for interpretation) ----
    "F0": { family: "fertility", label: "fertility_none", renderHint: "none" },
    "F1": { family: "fertility", label: "fertility_low", renderHint: "low" },
    "F2": { family: "fertility", label: "fertility_mid", renderHint: "mid" },
    "F3": { family: "fertility", label: "fertility_high", renderHint: "high" },

    // ---- Water ----
    "W0": { family: "water", label: "no_water", renderHint: "none" },
    "W1": { family: "water", label: "river", renderHint: "blue_river" },
    "W2": { family: "water", label: "lake", renderHint: "blue_lake" },

    // ---- Paths ----
    "P0": { family: "paths", label: "no_path", renderHint: "none" },
    "P1": { family: "paths", label: "dirt_path", renderHint: "dirt" },
    "P2": { family: "paths", label: "stone_path", renderHint: "stone" },

    // ---- Structures ----
    "S0": { family: "structures", label: "none", renderHint: "none" },
    "S1": { family: "structures", label: "farm_small", renderHint: "farm_small" },
    "S2": { family: "structures", label: "house", renderHint: "house" },
    "S3": { family: "structures", label: "storage", renderHint: "storage" },

    // ---- Units (Zips) ----
    "U0": { family: "units", label: "none", renderHint: "none" },
    "U1": { family: "units", label: "zip_worker_m", renderHint: "zip_m" },
    "U2": { family: "units", label: "zip_worker_f", renderHint: "zip_f" },
  } as const,

  /**
   * Reserved codes:
   * - "∅" may be used by tools for internal empty representation,
   *   but MUST NOT appear in a published payload.
   */
  reserved: {
    internalEmpty: "∅",
  },
} as const;

export type TilemapContractV1 = typeof TILEMAP_CONTRACT_V1;
export type TileLayerV1 = (typeof TILEMAP_CONTRACT_V1.layers)[number];
export type TileCodeV1 = keyof typeof TILEMAP_CONTRACT_V1.dictionary;

export type TileDefinitionV1 = {
  family: (typeof TILEMAP_CONTRACT_V1.layers)[number];
  label: string;
  renderHint: string;
};

/**
 * Canonical payload (what map exporters and SolumView consumers exchange).
 */
export type TilemapPayloadV1 = {
  contract: TilemapContractV1["id"];
  version: TilemapContractV1["version"];
  width: number;
  height: number;
  layers: Record<TileLayerV1, TileCodeV1[]>;
  /**
   * Optional metadata — must not affect rendering unless explicitly defined
   * by a later contract version.
   */
  meta?: {
    seed?: string; // informational only (generation belongs elsewhere)
    createdAt?: string;
    notes?: string;
  };
};

/**
 * Minimal runtime validation (no external deps).
 * Fail-closed on unknown codes and shape mismatches.
 */
export function validateTilemapPayloadV1(payload: unknown): { ok: true } | { ok: false; error: string } {
  if (!payload || typeof payload !== "object") return { ok: false, error: "payload_not_object" };

  const p = payload as any;

  if (p.contract !== TILEMAP_CONTRACT_V1.id) return { ok: false, error: "contract_id_mismatch" };
  if (p.version !== TILEMAP_CONTRACT_V1.version) return { ok: false, error: "contract_version_mismatch" };

  const width = p.width;
  const height = p.height;
  if (!Number.isInteger(width) || width <= 0) return { ok: false, error: "invalid_width" };
  if (!Number.isInteger(height) || height <= 0) return { ok: false, error: "invalid_height" };

  const expectedLen = width * height;

  if (!p.layers || typeof p.layers !== "object") return { ok: false, error: "layers_missing" };

  for (const layer of TILEMAP_CONTRACT_V1.layers) {
    const arr = p.layers[layer];
    if (!Array.isArray(arr)) return { ok: false, error: `layer_not_array:${layer}` };
    if (arr.length !== expectedLen) return { ok: false, error: `layer_length_mismatch:${layer}` };

    for (let i = 0; i < arr.length; i++) {
      const code = arr[i];
      if (typeof code !== "string") return { ok: false, error: `tile_code_not_string:${layer}:${i}` };
      if (code === TILEMAP_CONTRACT_V1.reserved.internalEmpty) return { ok: false, error: `reserved_code_used:${layer}:${i}` };
      if (!(code in TILEMAP_CONTRACT_V1.dictionary)) return { ok: false, error: `unknown_code:${layer}:${i}:${code}` };
    }
  }

  return { ok: true };
}

/**
 * Helper: get tile definition from code.
 */
export function tileDefV1(code: TileCodeV1): TileDefinitionV1 {
  return TILEMAP_CONTRACT_V1.dictionary[code];
}

/**
 * Helper: row-major index.
 */
export function idxV1(x: number, y: number, width: number): number {
  return y * width + x;
}
