/**
 * SolumView — UI Tokens Contract (v1)
 * ----------------------------------
 *
 * UI tokens are stable identifiers used by the SolumView frontend.
 * They encode *what the user is seeing* at the UI layer without encoding *how it looks*.
 *
 * This file is intentionally "boring":
 * - deterministic
 * - auditable
 * - append-only
 *
 * If a token is not defined here, it must not exist in SolumView UI.
 */

import { ICON_CATALOG_VERSION } from "./icon_catalog.contract.v1";

/* ============================== */
/* ===== Version & Metadata ===== */
/* ============================== */

export const UI_TOKENS_VERSION = "v1";
export const UI_TOKENS_STATUS = "canonical";

/**
 * Hard reference to the icon catalog version this UI contract is compatible with.
 * (Not a runtime enforcement — a canonical binding for audits.)
 */
export const UI_TOKENS_ICON_CATALOG_VERSION = ICON_CATALOG_VERSION;

/* ============================== */
/* ===== Token Categories ======= */
/* ============================== */

export enum UiTokenCategory {
  NAV = "nav",
  BADGE = "badge",
  LABEL = "label",
  STATE = "state",
  MODE = "mode",
  METRIC = "metric",
}

/* ============================== */
/* ===== Token Definition ======= */
/* ============================== */

export interface UiToken {
  /** Stable identifier (snake_case) */
  id: string;

  /** Human meaning of this token */
  meaning: string;

  /** Category of UI usage */
  category: UiTokenCategory;

  /**
   * Optional canonical icon binding.
   * IMPORTANT: this is an identifier-only reference, not an asset.
   */
  iconId?: string;

  /** Optional notes for auditors and implementers */
  notes?: string;
}

/* ============================== */
/* ===== Canonical UI Tokens ==== */
/* ============================== */

export const UI_TOKENS: UiToken[] = [

  /* ---------- Modes ---------- */

  {
    id: "mode_world",
    meaning: "World mode (global view of SolumWorld)",
    category: UiTokenCategory.MODE,
    iconId: "world_core",
  },
  {
    id: "mode_wallet",
    meaning: "Wallet mode (inspect a single wallet/territory context)",
    category: UiTokenCategory.MODE,
    iconId: "wallet_colonist",
    notes: "Wallet mode may target connected wallet or any public wallet address.",
  },

  /* ---------- States ---------- */

  {
    id: "state_trading_off",
    meaning: "Trading disabled (pre-launch contract state)",
    category: UiTokenCategory.STATE,
    iconId: "locked_state",
  },
  {
    id: "state_trading_on",
    meaning: "Trading enabled (post-launch contract state)",
    category: UiTokenCategory.STATE,
  },
  {
    id: "state_data_pending",
    meaning: "Data is pending (not final under reorg/finality policy)",
    category: UiTokenCategory.STATE,
    iconId: "warning_state",
  },
  {
    id: "state_data_final",
    meaning: "Data is final (past finality threshold)",
    category: UiTokenCategory.STATE,
  },
  {
    id: "state_error",
    meaning: "Critical error state (invalid or incomplete inputs)",
    category: UiTokenCategory.STATE,
    iconId: "error_state",
  },

  /* ---------- Badges / Labels ---------- */

  {
    id: "badge_veteran",
    meaning: "Veteran colonist (time-based classification)",
    category: UiTokenCategory.BADGE,
    iconId: "wallet_veteran",
  },
  {
    id: "badge_major_holder",
    meaning: "Major territory holder (size-based classification)",
    category: UiTokenCategory.BADGE,
    iconId: "wallet_major_holder",
  },
  {
    id: "badge_virgin_territory",
    meaning: "Virgin territory (no outgoing activity since acquisition)",
    category: UiTokenCategory.BADGE,
    iconId: "territory_virgin",
  },
  {
    id: "label_treasury",
    meaning: "Treasury address or treasury-related UI section",
    category: UiTokenCategory.LABEL,
    iconId: "treasury",
  },
  {
    id: "label_liquidity_pool",
    meaning: "Liquidity pool section (reserves/spot price surface)",
    category: UiTokenCategory.LABEL,
    iconId: "liquidity_pool",
  },

  /* ---------- Metrics (names, not computations) ---------- */

  {
    id: "metric_total_supply",
    meaning: "Total supply (live)",
    category: UiTokenCategory.METRIC,
    notes: "Computation defined in Solumtools + SolumWorld specs.",
  },
  {
    id: "metric_burned_supply",
    meaning: "Burned supply (genesis - total supply)",
    category: UiTokenCategory.METRIC,
    iconId: "burned_land",
    notes: "Displayed as permanent geography in SolumWorld interpretation.",
  },
  {
    id: "metric_pool_reserves",
    meaning: "Pool reserves (SOLUM/WETH)",
    category: UiTokenCategory.METRIC,
    iconId: "liquidity_pool",
  },
];

/* ============================== */
/* ===== Determinism Rules ====== */
/* ============================== */

/**
 * Determinism & Audit Rules:
 * - UI_TOKENS is append-only.
 * - Do not reorder existing tokens.
 * - Do not delete tokens; deprecate via new version if needed.
 * - Token meaning must remain stable over time.
 *
 * Same state → same token → same UI meaning.
 */
