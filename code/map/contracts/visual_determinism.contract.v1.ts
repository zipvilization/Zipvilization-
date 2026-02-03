/**
 * Zipvilization — Solumview
 * VISUAL DETERMINISM CONTRACT v1
 *
 * Purpose:
 * - Define a deterministic mapping from verified/derived STATE into VIEW tokens.
 * - Guarantee that "what users see" is stable, reproducible, and auditable.
 *
 * Non-goals:
 * - Rendering implementation (canvas/webgl/etc)
 * - Asset storage (sprites/icons/fonts)
 * - Any off-chain identity inference
 * - Predictive / future frames
 *
 * Fail-closed principle:
 * - If required inputs are missing or inconsistent, return HALT with a reason.
 */

export const VISUAL_DETERMINISM_CONTRACT_V1 = {
  id: "visual_determinism.contract.v1",
  status: "alpha",
  scope: "solumview",
  principles: {
    deterministic: true,
    auditable: true,
    failClosed: true,
    noFutureFrames: true,
    noInventedSignals: true,
  },

  /**
   * Canonical inputs required to derive a visual representation.
   * Notes:
   * - "walletMode" does not create an alternative timeline.
   *   It is a filtered projection of the same world evolution.
   */
  inputs: {
    // Versioning
    contract_version: "visual_determinism.contract.v1",

    // Context
    chain_id: "number",
    world_id: "string", // stable identifier (e.g., "zipvilization.base.mainnet")
    view_mode: ["WORLD", "WALLET"],

    // Timeline anchor (retrospective only)
    epoch: {
      type: "object",
      required: ["epoch_type", "epoch_id"],
      fields: {
        epoch_type: ["LIVE", "BLOCK", "FRAME"],
        epoch_id: "string", // e.g., "live", "block:123456", "frame:2026-02-01T00:00Z"
      },
    },

    // Zoom anchor (must follow SolumWorld zoom rules)
    zoom: {
      type: "object",
      required: ["zoom_level"],
      fields: {
        zoom_level: ["ZOOM_0", "ZOOM_1", "ZOOM_2", "ZOOM_3", "MAX"],
        // optional viewport framing for UI, not for rules
        viewport: "optional<object>",
      },
    },

    // Wallet anchor (only when view_mode=WALLET)
    wallet: {
      type: "object",
      optional: true,
      fields: {
        address: "string", // 0x...
        // optional: explicit “focus parcel” selector
        focus: "optional<object>",
      },
    },

    /**
     * Deterministic seeds:
     * - world_seed is constant for the world_id
     * - epoch_seed is derived from epoch_id
     * - wallet_seed is derived from wallet address
     *
     * Seeds must be explicit to make the mapping auditable.
     */
    seeds: {
      type: "object",
      required: ["world_seed", "epoch_seed"],
      fields: {
        world_seed: "string",
        epoch_seed: "string",
        wallet_seed: "optional<string>",
      },
    },

    /**
     * Canonical state bundle (no visuals):
     * - must come from SolumWorld / Solumtools / evolution layer.
     * - Visual contract does not compute blockchain metrics.
     */
    state_bundle: {
      type: "object",
      required: ["state_id", "invariants_ok", "sources"],
      fields: {
        state_id: "string", // e.g. "state:live" or "state:frame:..."
        invariants_ok: "boolean",
        sources: "object", // references to canonical sources (contract/pool/events)
        // world/wallet state payload is opaque here (validated by state contract),
        // but we require it to exist.
        payload: "object",
      },
    },

    /**
     * Catalog versions:
     * - These are versioned files in repo (icons/palettes/fonts).
     * - Visual determinism depends on them, but does not embed them.
     */
    catalogs: {
      type: "object",
      required: ["icon_catalog_version", "palette_catalog_version", "ui_tokens_version"],
      fields: {
        icon_catalog_version: "string",    // e.g. "icons.v1"
        palette_catalog_version: "string", // e.g. "palette.v1"
        ui_tokens_version: "string",       // e.g. "ui.v1"
      },
    },
  },

  /**
   * Deterministic outputs:
   * - A renderer consumes these tokens to draw the view.
   * - Output MUST include trace fields for auditability.
   */
  outputs: {
    decision: ["PASS", "HALT"],

    audit: {
      type: "object",
      required: ["ruleset_id", "inputs_hash", "catalog_versions", "notes"],
      fields: {
        ruleset_id: "string", // "visual_determinism.contract.v1"
        inputs_hash: "string", // deterministic hash of inputs (implementation-defined)
        catalog_versions: "object",
        notes: "string[]",
      },
    },

    view_tokens: {
      type: "object",
      required: ["zoom_level", "layers"],
      fields: {
        zoom_level: "string",
        /**
         * Layers are strict and ordered.
         * Renderers may not reorder them.
         */
        layers: "array<layer>",
      },
    },

    warnings: "string[]",
    errors: "string[]",
  },

  /**
   * Canonical layer model:
   * - base terrain (tiles)
   * - hydrology/forests (derived from permanent geography)
   * - settlements/structures (derived from activity & evolution)
   * - overlays (UI-level annotations)
   * - entities/icons (catalog referenced)
   */
  layer_model: {
    layer: {
      type: "object",
      required: ["id", "kind", "data"],
      fields: {
        id: "string",
        kind: [
          "TERRAIN_TILES",
          "GEOGRAPHY_OVERLAY",
          "STRUCTURES",
          "ROADS",
          "FIELDS",
          "ENTITIES",
          "UI_OVERLAY",
          "DEBUG",
        ],
        data: "object",
      },
    },
  },

  /**
   * Hard invariants:
   * If any fails => HALT.
   */
  invariants: [
    "state_bundle.invariants_ok MUST be true",
    "epoch MUST be retrospective (LIVE is allowed; future frames are forbidden)",
    "zoom_level MUST match SolumWorld zoom rules",
    "catalog versions MUST be provided",
    "view_mode=WALLET requires wallet.address",
  ],

  /**
   * Determinism rules:
   * These rules do not compute metrics; they map already-computed state to visuals.
   * Each rule must be reproducible from inputs + catalogs.
   */
  rules: {
    /**
     * The visual mapping is split into:
     * - selection: choose which subset of state is visible (wallet filter)
     * - encoding: convert signals to discrete visual codes (tile ids, overlay ids)
     * - layering: construct ordered layers
     */
    selection: {
      world: "Use state_bundle.payload as-is.",
      wallet:
        "Filter state_bundle.payload to the wallet projection. Never create a separate timeline. The same epoch applies.",
    },

    encoding: {
      /**
       * Visual codes:
       * - Must be discrete identifiers (no floating colors).
       * - All ids must exist in catalogs.
       */
      terrain_tiles: {
        principle:
          "Base terrain is derived from permanent geography + fertility + time, encoded as discrete tile IDs.",
        note:
          "Exact mapping tables live in docs/Solumview and catalogs; this contract enforces the presence of IDs only.",
      },

      icons: {
        principle:
          "Entities/structures use icon IDs from icon catalog. No ad-hoc icons are allowed.",
      },

      ui_tokens: {
        principle:
          "UI overlays (labels, highlights, tooltips) use UI token IDs from ui catalog. No inline styling.",
      },
    },

    layering: {
      order: [
        "TERRAIN_TILES",
        "GEOGRAPHY_OVERLAY",
        "FIELDS",
        "ROADS",
        "STRUCTURES",
        "ENTITIES",
        "UI_OVERLAY",
      ],
      note:
        "Renderers must preserve layer order to keep determinism across clients.",
    },
  },

  /**
   * Validation procedure (spec-level).
   * Implementation should follow this flow and fail closed.
   */
  validate(input: any) {
    const errors: string[] = [];
    const warnings: string[] = [];

    const req = (cond: boolean, msg: string) => {
      if (!cond) errors.push(msg);
    };

    // Basic required fields
    req(!!input, "MISSING_INPUT");
    req(input?.state_bundle?.invariants_ok === true, "STATE_INVARIANTS_NOT_OK");
    req(!!input?.catalogs, "MISSING_CATALOGS");
    req(!!input?.seeds?.world_seed, "MISSING_WORLD_SEED");
    req(!!input?.seeds?.epoch_seed, "MISSING_EPOCH_SEED");
    req(!!input?.zoom?.zoom_level, "MISSING_ZOOM_LEVEL");
    req(!!input?.epoch?.epoch_type && !!input?.epoch?.epoch_id, "MISSING_EPOCH");

    // Wallet mode requirements
    if (input?.view_mode === "WALLET") {
      req(!!input?.wallet?.address, "WALLET_MODE_REQUIRES_ADDRESS");
      if (!input?.seeds?.wallet_seed) {
        warnings.push("WALLET_SEED_NOT_PROVIDED (recommended for strict determinism)");
      }
    }

    // No future frames rule (spec-level)
    // Future detection is implementation-defined; we enforce intent via epoch_type.
    if (input?.epoch?.epoch_type === "FRAME") {
      // frames are allowed only if they are known/published. We can't prove here,
      // so we require the caller to supply a stable epoch_id.
      req(
        typeof input?.epoch?.epoch_id === "string" && input.epoch.epoch_id.startsWith("frame:"),
        "INVALID_FRAME_EPOCH_ID"
      );
    }

    const decision = errors.length ? "HALT" : "PASS";

    return {
      decision,
      errors,
      warnings,
      audit: {
        ruleset_id: "visual_determinism.contract.v1",
        inputs_hash: "implementation_defined",
        catalog_versions: input?.catalogs ?? {},
        notes: [
          "This contract maps STATE -> VIEW tokens deterministically.",
          "Renderers must not reorder layers or invent missing ids.",
          "Wallet mode is a filtered projection of the same world timeline.",
        ],
      },
    };
  },
} as const;

export type VisualDeterminismContractV1 = typeof VISUAL_DETERMINISM_CONTRACT_V1;
