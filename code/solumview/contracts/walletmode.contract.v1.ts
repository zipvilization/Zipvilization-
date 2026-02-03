/**
 * Zipvilization — SolumView
 * Wallet Mode Contract v1 (CANONICAL)
 *
 * Wallet Mode allows:
 * - Connect wallet (your own)
 * - Lookup any wallet (public)
 * - Inspect as territory (deterministic projection)
 *
 * Wallet Mode is READ-ONLY: it does not write, execute, or request signatures.
 * It only selects and renders deterministic views from public on-chain data.
 */

export const WALLETMODE_CONTRACT_V1 = {
  meta: {
    contract_id: "solumview.walletmode.contract.v1",
    version: 1,
    status: "alpha",
    scope: "solumview",
    canonical: true
  },

  /**
   * Supported entry points
   */
  entrypoints: [
    {
      id: "connect",
      description:
        "User connects their wallet. SolumView resolves territory and opens a default view."
    },
    {
      id: "lookup",
      description:
        "User searches/inputs any wallet address. SolumView resolves territory and opens an inspection view."
    },
    {
      id: "inspect",
      description:
        "Direct inspection by a known wallet address (deep link / url / internal navigation)."
    }
  ],

  /**
   * Public by design:
   * - any wallet is viewable (blockchain is public)
   * - no private dashboards exist here
   */
  visibility: {
    public_lookup: true,
    private_views: false,
    notes: [
      "Wallet Mode does not assume identity, ownership, or intent.",
      "Wallet labels, if any, must be purely structural (e.g., 'treasury', 'pair') and auditable."
    ]
  },

  /**
   * Deterministic territory targeting rules
   *
   * Wallet Mode must resolve a wallet into a stable territory representation.
   * This contract does not define the mapping algorithm; it defines constraints:
   * - stable (same wallet => same territory anchor across builds)
   * - auditable (mapping is explainable, reproducible)
   * - non-arbitrary (no random selection)
   */
  targeting: {
    input: {
      required: ["wallet_address"],
      format: "0x-prefixed EVM address (20 bytes)",
      normalize: "checksum is optional, but canonical output should be checksummed if available"
    },

    resolution_outputs: {
      // A territory_id can be a stable identifier derived by backend rules.
      // If not available, it must be explicitly unresolved.
      fields: [
        "wallet_address",
        "territory_id | null",
        "resolution_status",
        "resolution_reason"
      ],
      resolution_status: [
        "resolved",      // territory_id present and valid
        "unresolved",    // mapping not available yet
        "invalid_input"  // bad address format
      ]
    },

    constraints: [
      "Mapping must be stable across time for the same wallet (unless a new canonical mapping version is published).",
      "If mapping cannot be computed, status must be 'unresolved' (never fabricate territory_id).",
      "Territory anchor used by Zoom Contract must match wallet-derived anchor rules.",
      "If the wallet has 0 balance, SolumView may still render: territory exists as a potential/empty state, not as invented content."
    ]
  },

  /**
   * Default view rules
   * When a wallet is connected/lookup, which view opens first?
   *
   * These are canonical defaults (UI can offer alternatives).
   */
  defaults: {
    initial_zoom_level: 2, // "territory" zoom (see Zoom Contract v1)
    initial_view_scope: "wallet",
    initial_moment: "current",
    allowed_moments: ["moment0", "current", "range"],

    notes: [
      "moment0 represents the initial arid world state + initial seeding rules.",
      "current represents the latest finalized chain-derived view.",
      "range is a playback window (requires Evolution Contract)."
    ]
  },

  /**
   * Output shape expectations (for SolumView UI)
   * This is what the backend/provider must supply to the frontend renderer.
   */
  output_requirements: {
    must_include: [
      "view.scope",
      "view.zoom_level",
      "view.anchor",
      "view.moment",
      "wallet.wallet_address",
      "wallet.resolution_status",
      "chunks[] (tilemaps) OR explicit empty state"
    ],

    anchor_shape: {
      // Must align with Zoom Contract v1 anchors.wallet
      type: "derived",
      fields: ["wallet_address", "territory_id | null"]
    },

    empty_states: [
      {
        id: "unresolved",
        when: "wallet.resolution_status == 'unresolved'",
        rule:
          "UI must show 'mapping not available yet' rather than generating a fake territory."
      },
      {
        id: "zero_balance",
        when: "wallet has 0 Solum (derived by balanceOf)",
        rule:
          "UI may show an empty/arid territory state, but it must be explicitly derived (not decorative invention)."
      }
    ]
  },

  /**
   * Non-goals / prohibitions
   */
  non_goals: [
    "No wallet tagging by off-chain identity claims.",
    "No predictions, recommendations, or financial advice.",
    "No write actions: no signatures, no approvals, no tx crafting."
  ]
} as const;

export type WalletModeContractV1 = typeof WALLETMODE_CONTRACT_V1;
