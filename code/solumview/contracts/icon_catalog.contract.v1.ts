/**
 * SolumView — Icon Catalog Contract (v1)
 * -------------------------------------
 *
 * This file defines the canonical registry of visual symbols
 * that may appear in SolumView.
 *
 * Icons are semantic identifiers.
 * They do NOT define shape, color, size, or style.
 *
 * If an icon is not declared here, it does not exist canonically.
 */

/* ============================== */
/* ===== Version & Metadata ===== */
/* ============================== */

export const ICON_CATALOG_VERSION = "v1";
export const ICON_CATALOG_STATUS = "canonical";

/* ============================== */
/* ===== Icon Scope Enum ======== */
/* ============================== */

/**
 * Scope defines where an icon is allowed to appear.
 */
export enum IconScope {
  WORLD = "world",
  TERRITORY = "territory",
  WALLET = "wallet",
  SYSTEM = "system",
  UI_STATE = "ui_state",
}

/* ============================== */
/* ===== Icon Lifecycle ========= */
/* ============================== */

export enum IconLifecycle {
  ACTIVE = "active",
  DEPRECATED = "deprecated",
  RESERVED = "reserved",
}

/* ============================== */
/* ===== Icon Definition ======== */
/* ============================== */

export interface IconDefinition {
  /** Unique, stable identifier */
  id: string;

  /** Human-readable semantic meaning */
  meaning: string;

  /** Where this icon may appear */
  scope: IconScope[];

  /** Lifecycle state */
  lifecycle: IconLifecycle;

  /** Optional notes for future interpretation */
  notes?: string;
}

/* ============================== */
/* ===== Canonical Icons ======== */
/* ============================== */

export const ICON_CATALOG: IconDefinition[] = [

  /* ---------- World / Geography ---------- */

  {
    id: "world_core",
    meaning: "Canonical representation of the SolumWorld base layer",
    scope: [IconScope.WORLD],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "burned_land",
    meaning: "Permanently burned territory (irreversible geography)",
    scope: [IconScope.WORLD, IconScope.TERRITORY],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "frontier_land",
    meaning: "Uncolonized or pool-backed territory",
    scope: [IconScope.WORLD],
    lifecycle: IconLifecycle.ACTIVE,
  },

  /* ---------- Territory / Colonization ---------- */

  {
    id: "territory_owned",
    meaning: "Territory currently owned by a colonist",
    scope: [IconScope.TERRITORY, IconScope.WALLET],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "territory_virgin",
    meaning: "Territory with no outgoing activity since acquisition",
    scope: [IconScope.TERRITORY],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "territory_active",
    meaning: "Territory with recent on-chain activity",
    scope: [IconScope.TERRITORY],
    lifecycle: IconLifecycle.ACTIVE,
  },

  /* ---------- Wallet / Colonist ---------- */

  {
    id: "wallet_colonist",
    meaning: "Standard colonist wallet",
    scope: [IconScope.WALLET],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "wallet_veteran",
    meaning: "Long-standing colonist (time-based role)",
    scope: [IconScope.WALLET],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "wallet_major_holder",
    meaning: "Large territory holder",
    scope: [IconScope.WALLET],
    lifecycle: IconLifecycle.ACTIVE,
  },

  /* ---------- System / Protocol ---------- */

  {
    id: "treasury",
    meaning: "Protocol treasury address",
    scope: [IconScope.SYSTEM],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "liquidity_pool",
    meaning: "DEX liquidity pool",
    scope: [IconScope.SYSTEM],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "reflection_flow",
    meaning: "Reflection redistribution flow",
    scope: [IconScope.SYSTEM],
    lifecycle: IconLifecycle.ACTIVE,
  },

  /* ---------- UI State ---------- */

  {
    id: "locked_state",
    meaning: "Feature or view not yet available",
    scope: [IconScope.UI_STATE],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "warning_state",
    meaning: "Non-critical warning state",
    scope: [IconScope.UI_STATE],
    lifecycle: IconLifecycle.ACTIVE,
  },

  {
    id: "error_state",
    meaning: "Critical error or invalid state",
    scope: [IconScope.UI_STATE],
    lifecycle: IconLifecycle.ACTIVE,
  },
];

/* ============================== */
/* ===== Determinism Rules ====== */
/* ============================== */

/**
 * - Icons are immutable once ACTIVE.
 * - Deprecated icons remain readable forever.
 * - New icons must be appended, never reordered.
 * - Removal requires a new catalog version.
 *
 * Same state → same icon → same meaning.
 */
