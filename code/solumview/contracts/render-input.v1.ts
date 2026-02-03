/**
 * SolumView — Render Input Contract (v1)
 *
 * Purpose:
 * - Define the minimal, stable, versioned payload SolumView can render.
 *
 * Constraints:
 * - No chain access inside SolumView
 * - No business interpretation inside SolumView
 * - Deterministic rendering: same input => same output
 */

export type RenderInputVersion = "1.0";

/**
 * High-level mode for the viewer.
 * - WORLD: generic world view (no wallet focus)
 * - WALLET: wallet-focused view (searchable / connectable)
 */
export type ViewMode = "WORLD" | "WALLET";

/**
 * Evolution mode determines which time-slice is being rendered.
 * - LIVE: current state
 * - SNAPSHOT: explicit historical snapshot
 */
export type EvolutionMode = "LIVE" | "SNAPSHOT";

/**
 * Zoom level must map to SolumWorld zoom rules.
 * SolumView does not invent zoom semantics. It only consumes them.
 */
export type ZoomLevel = 0 | 1 | 2 | 3;

/**
 * Deterministic seed used for purely visual pseudo-random choices
 * (noise, placement jitter, micro-variations). Must be stable.
 */
export type DeterminismSeed = string;

/**
 * Canonical address format (lowercase, 0x-prefixed).
 * SolumView treats it as opaque identity.
 */
export type Address = `0x${string}`;

/**
 * RenderInputV1 is the single payload SolumView needs to render.
 */
export interface RenderInputV1 {
  meta: {
    version: RenderInputVersion;

    /** network id, e.g. Base = 8453 (kept numeric for tooling) */
    chainId: number;

    /** block/time context for the snapshot being rendered */
    blockNumber: number;
    blockTimestamp: number;

    /**
     * snapshotId is an external identifier (hash/slug) that tooling can use
     * to reference stored snapshots. SolumView does not resolve it.
     */
    snapshotId?: string;

    /**
     * Deterministic seed for visual decisions.
     * Recommended: `${chainId}:${blockNumber}:${targetAddress || "world"}`
     */
    seed: DeterminismSeed;
  };

  target: {
    /**
     * View mode: WORLD or WALLET.
     * WALLET mode may show a specific wallet or a connected wallet.
     */
    mode: ViewMode;

    /** If mode=WALLET, the wallet being visualized (searched or connected). */
    address?: Address;

    /**
     * Human-facing label, optional.
     * Never treated as authoritative identity.
     */
    label?: string;
  };

  viewport: {
    zoom: ZoomLevel;

    /**
     * Camera target in world coordinates.
     * Coordinates are abstract and defined by SolumWorld exporter.
     */
    center: { x: number; y: number };

    /**
     * Output dimensions (pixels). Helps renderers decide tile scaling.
     */
    sizePx: { width: number; height: number };

    /**
     * Tile size in pixels (visual grid). Must be deterministic.
     */
    tilePx: number;
  };

  evolution: {
    mode: EvolutionMode;

    /**
     * If SNAPSHOT, defines the historical selection.
     * SolumView does not compute history; it only renders it.
     */
    snapshot?: {
      /** unix timestamp range or a single timestamp */
      atTimestamp?: number;
      fromTimestamp?: number;
      toTimestamp?: number;
    };
  };

  /**
   * World payload is a minimal render-friendly subset.
   * It is produced by upstream tooling (Solumtools/SolumWorld exporter).
   */
  world: {
    /**
     * The render chunk is the bounded set of tiles/objects relevant to viewport.
     * Avoid sending the whole world.
     */
    chunk: {
      origin: { x: number; y: number };
      width: number;
      height: number;

      /**
       * Terrain tiles: numeric ids mapped to ICONS_CONTRACT palette
       * or explicit enum ids if preferred later.
       */
      tiles: number[]; // length = width * height

      /**
       * Optional overlays: rivers, roads, borders, etc.
       * Kept generic to avoid locking too early.
       */
      overlays?: Array<{
        type: string; // e.g. "river" | "road" | "border"
        points: Array<{ x: number; y: number }>;
        styleId?: string;
      }>;
    };

    /**
     * Renderable entities inside the chunk.
     * Examples: farms, settlements, markers, structures.
     */
    entities?: Array<{
      id: string;
      type: string; // e.g. "settlement" | "farm" | "marker"
      pos: { x: number; y: number };
      size?: { w: number; h: number };
      iconId?: string;
      meta?: Record<string, string | number | boolean>;
    }>;
  };

  ui: {
    /**
     * Which UI overlays are enabled. SolumView only renders them.
     */
    overlays: {
      showGrid?: boolean;
      showLabels?: boolean;
      showBorders?: boolean;
      showActivityHeat?: boolean;
      showTimeline?: boolean;
    };

    /**
     * Wallet mode extras: search + connect are UI features.
     * SolumView does not authenticate; it just reflects state.
     */
    wallet?: {
      canSearchAnyWallet: boolean;
      canConnectWallet: boolean;
    };
  };

  assets: {
    /**
     * Declares which asset packs / palettes should be used.
     * All IDs must correspond to docs/SolumView ICONS_CONTRACT + UI_CONTRACT.
     */
    paletteId: string;
    iconSetId: string;
    spriteSetId?: string;
  };
}

/**
 * Type guard for runtime validation (minimal).
 * Real validation should be done by upstream tooling.
 */
export function isRenderInputV1(x: any): x is RenderInputV1 {
  return (
    x &&
    x.meta?.version === "1.0" &&
    typeof x.meta.chainId === "number" &&
    typeof x.meta.blockNumber === "number" &&
    typeof x.meta.blockTimestamp === "number" &&
    typeof x.meta.seed === "string" &&
    x.viewport &&
    typeof x.viewport.zoom === "number" &&
    x.viewport.center &&
    typeof x.viewport.center.x === "number" &&
    typeof x.viewport.center.y === "number" &&
    x.world?.chunk &&
    typeof x.world.chunk.width === "number" &&
    typeof x.world.chunk.height === "number" &&
    Array.isArray(x.world.chunk.tiles)
  );
}
