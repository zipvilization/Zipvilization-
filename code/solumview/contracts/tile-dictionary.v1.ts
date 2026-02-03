/**
 * Tile Dictionary — v1
 * Canonical contract for SolumView.
 *
 * Purpose:
 * - Provide a deterministic mapping: tileId (number) -> semantic meaning (minimal) + rendering intent (minimal).
 *
 * Non-goals:
 * - No rendering, no palette, no sprite atlas definitions.
 * - No SolumWorld logic, no Solumtools computations.
 *
 * Canonical invariants:
 * - tileId 0 is ALWAYS "void" / "no-data" across all versions.
 * - Keys are stable machine identifiers (snake_case recommended).
 * - A new dictionary version can add new tiles, but must preserve the meaning of existing ids unless explicitly deprecated.
 */

export type TileId = number;

export type TileKind =
  | "void"
  | "terrain"
  | "water"
  | "vegetation"
  | "structure"
  | "resource"
  | "marker";

export interface TileEntryV1 {
  /** Integer >= 0. */
  id: TileId;

  /**
   * Stable machine key. This is NOT localized text.
   * Example: "arid_land", "fertile_land", "forest_dense"
   */
  key: string;

  /** Minimal category for tooling and UI grouping. */
  kind: TileKind;

  /**
   * Minimal human description (short, neutral).
   * Avoid narrative lore here; lore belongs in docs, not in contracts.
   */
  label: string;

  /**
   * Rendering hint: not a sprite pointer.
   * This is intentionally minimal and abstract.
   */
  render: {
    /** "flat" for tiles, "overlay" for markers, etc. */
    layer: "base" | "overlay";
    /**
     * A symbolic token the renderer can map to visuals.
     * Example: "soil_arid", "soil_fertile", "water_river"
     */
    glyph: string;
  };

  /**
   * Optional notes for maintainers.
   * Must not change determinism; purely informational.
   */
  notes?: string;
}

export interface TileDictionaryV1 {
  /** Contract name. */
  contract: "TileDictionaryV1";

  /**
   * Version id (semantic-ish, but strictly a string).
   * Example: "v1", "v1.1", "v2"
   */
  version: string;

  /**
   * The reserved invariant ids.
   * These must always exist with the same key+kind meaning.
   */
  invariants: {
    /** Always: 0 */
    voidId: 0;
    /** Always: key for 0 */
    voidKey: "void";
  };

  /**
   * The dictionary entries.
   * Must include id 0 = void.
   */
  tiles: TileEntryV1[];
}

/* ============================================================
 * Canonical v1 dictionary (minimal starter set)
 * ============================================================
 *
 * This is the initial baseline. It is intentionally small.
 * Add tiles only when SolumWorld/Solumtools outputs require them.
 */

export const TILE_DICTIONARY_V1: TileDictionaryV1 = {
  contract: "TileDictionaryV1",
  version: "v1",
  invariants: {
    voidId: 0,
    voidKey: "void",
  },
  tiles: [
    {
      id: 0,
      key: "void",
      kind: "void",
      label: "No data / outside of rendered area",
      render: { layer: "base", glyph: "void" },
      notes: "Invariant: tileId 0 is always void across all versions.",
    },

    // --- Terrain baseline ---
    {
      id: 1,
      key: "arid_land",
      kind: "terrain",
      label: "Arid land (initial / low fertility)",
      render: { layer: "base", glyph: "soil_arid" },
    },
    {
      id: 2,
      key: "fertile_land",
      kind: "terrain",
      label: "Fertile land (cultivable)",
      render: { layer: "base", glyph: "soil_fertile" },
    },

    // --- Vegetation baseline ---
    {
      id: 3,
      key: "forest",
      kind: "vegetation",
      label: "Forest / wild vegetation",
      render: { layer: "base", glyph: "forest" },
    },

    // --- Water baseline ---
    {
      id: 4,
      key: "river",
      kind: "water",
      label: "River / water flow",
      render: { layer: "base", glyph: "water_river" },
    },

    // --- Structures baseline (very early) ---
    {
      id: 5,
      key: "settlement",
      kind: "structure",
      label: "Settlement / built presence",
      render: { layer: "overlay", glyph: "settlement" },
      notes: "Used when SolumWorld marks early civilization emergence at higher zooms.",
    },

    // --- Markers baseline ---
    {
      id: 6,
      key: "parcel_origin",
      kind: "marker",
      label: "Parcel origin / anchor marker",
      render: { layer: "overlay", glyph: "origin_marker" },
      notes: "Optional marker tile. Not required in all zooms.",
    },
  ],
};

/* ============================================================
 * Validation (fail-closed)
 * ============================================================
 */

export type TileDictionaryValidationResult =
  | { ok: true }
  | { ok: false; error: string };

export function validateTileDictionaryV1(
  dict: TileDictionaryV1
): TileDictionaryValidationResult {
  if (!dict || dict.contract !== "TileDictionaryV1") {
    return { ok: false, error: "INVALID_CONTRACT" };
  }
  if (!dict.version || typeof dict.version !== "string") {
    return { ok: false, error: "INVALID_VERSION" };
  }
  if (!dict.tiles || !Array.isArray(dict.tiles)) {
    return { ok: false, error: "TILES_NOT_ARRAY" };
  }

  // Must include invariant tile 0
  const voidTile = dict.tiles.find((t) => t.id === 0);
  if (!voidTile) return { ok: false, error: "MISSING_VOID_TILE" };
  if (voidTile.key !== dict.invariants.voidKey) {
    return { ok: false, error: "VOID_KEY_MISMATCH" };
  }
  if (voidTile.kind !== "void") {
    return { ok: false, error: "VOID_KIND_MISMATCH" };
  }

  const seenIds = new Set<number>();
  const seenKeys = new Set<string>();

  for (const t of dict.tiles) {
    if (!t) return { ok: false, error: "NULL_TILE_ENTRY" };

    if (!Number.isInteger(t.id) || t.id < 0) {
      return { ok: false, error: `INVALID_TILE_ID:${String(t.id)}` };
    }
    if (seenIds.has(t.id)) {
      return { ok: false, error: `DUPLICATE_TILE_ID:${String(t.id)}` };
    }
    seenIds.add(t.id);

    if (!t.key || typeof t.key !== "string") {
      return { ok: false, error: `INVALID_TILE_KEY:${String(t.id)}` };
    }
    if (seenKeys.has(t.key)) {
      return { ok: false, error: `DUPLICATE_TILE_KEY:${t.key}` };
    }
    seenKeys.add(t.key);

    if (!t.label || typeof t.label !== "string") {
      return { ok: false, error: `INVALID_TILE_LABEL:${t.key}` };
    }

    if (!t.render || typeof t.render !== "object") {
      return { ok: false, error: `INVALID_RENDER_BLOCK:${t.key}` };
    }
    if (t.render.layer !== "base" && t.render.layer !== "overlay") {
      return { ok: false, error: `INVALID_RENDER_LAYER:${t.key}` };
    }
    if (!t.render.glyph || typeof t.render.glyph !== "string") {
      return { ok: false, error: `INVALID_RENDER_GLYPH:${t.key}` };
    }
  }

  return { ok: true };
}
```0
