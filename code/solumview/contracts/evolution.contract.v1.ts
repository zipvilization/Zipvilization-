/**
 * Zipvilization — SolumView
 * Evolution Contract v1 (CANONICAL)
 *
 * Evolution = the ability to render the world across time:
 * - moment0  : the canonical baseline (arid world, pre-civilization)
 * - current  : latest finalized chain-derived view
 * - range    : playback window between two chain moments
 *
 * This contract defines deterministic rules, not implementation.
 */

export const EVOLUTION_CONTRACT_V1 = {
  meta: {
    contract_id: "solumview.evolution.contract.v1",
    version: 1,
    status: "alpha",
    scope: "solumview",
    canonical: true
  },

  /**
   * Definitions of moments
   */
  moments: {
    moment0: {
      id: "moment0",
      description:
        "Canonical baseline: the world is fully arid (brown/sterile) before any colonization is interpreted.",
      constraints: [
        "moment0 is NOT a blockchain snapshot.",
        "moment0 is a defined baseline state used for visual continuity and evolution playback.",
        "moment0 must be identical for all users (world-wide baseline)."
      ]
    },

    current: {
      id: "current",
      description:
        "Latest chain-derived state considered stable enough to render as 'current'.",
      finality_policy: {
        // choose a simple default; implementation may tighten, but never weaken silently
        mode: "block_window",
        window_blocks: 32,
        notes: [
          "current = head - window_blocks (finality threshold).",
          "If the chain reorganizes inside the window, reprocess and update outputs deterministically."
        ]
      }
    },

    range: {
      id: "range",
      description:
        "Playback window between two chain moments (block or timestamp boundaries).",
      constraints: [
        "range endpoints must be explicit (start and end).",
        "If endpoint cannot be resolved, fail closed with a readable error state (no fabrication)."
      ]
    }
  },

  /**
   * Time slicing strategy
   * How evolution frames are generated (not rendered).
   */
  slicing: {
    primary: "block_based",
    allowed: ["block_based", "timestamp_based"],
    block_based: {
      unit: "block",
      frame_rule: "sample every N blocks or by significant events",
      defaults: {
        // sane default: fewer frames early; more frames when activity spikes (implementation choice)
        sample_every_blocks: 50
      }
    },
    timestamp_based: {
      unit: "seconds",
      frame_rule: "sample into fixed windows (e.g., 1h / 1d)",
      defaults: {
        window_seconds: 3600
      }
    },
    determinism_rules: [
      "Given the same chain data + same slicing params, produced frames must be identical.",
      "Sampling decisions must be rule-based and documented (no heuristics that can drift silently)."
    ]
  },

  /**
   * What counts as 'evolution input'
   * SolumView evolution is derived from public on-chain signals (via Solumtools/SolumWorld).
   */
  inputs: {
    required_sources: [
      "solumtools.protocol.summary",
      "solumtools.pool.summary",
      "solumtools.wallet.summary (for wallet mode)",
      "solumtools.tx stream (typed: buy/sell/transfer) OR equivalent indexed dataset"
    ],
    constraints: [
      "If a signal cannot be derived from on-chain data or published specs, it must not exist.",
      "All derived fields must carry a source label: verified / derived / estimated."
    ]
  },

  /**
   * Output requirements for the frontend
   *
   * Two allowed output styles:
   * 1) snapshots: full tile chunks per frame
   * 2) deltas   : changes between frames (preferred for efficiency)
   */
  outputs: {
    timeline_meta: {
      must_include: [
        "mode (moment0|current|range)",
        "finality (final|preview)",
        "start (block|timestamp|null for moment0)",
        "end (block|timestamp|null for current/moment0 depending on mode)",
        "frame_count",
        "slicing_params"
      ]
    },

    frame_payload: {
      allowed_types: ["snapshot", "delta"],
      snapshot: {
        must_include: ["frame_id", "anchor", "chunks[]", "labels[]?"]
      },
      delta: {
        must_include: ["frame_id", "anchor", "changes[]", "base_frame_id"]
      },
      constraints: [
        "No frame may contain invented tiles not justified by prior states + derived rules.",
        "If data is missing, frame must declare partial status rather than hallucinating completion."
      ]
    }
  },

  /**
   * Caching & reproducibility
   */
  caching: {
    required: true,
    keys: [
      "contract_id/version",
      "view.anchor (world or wallet)",
      "moment/mode",
      "range endpoints (if range)",
      "slicing params",
      "finality threshold"
    ],
    rules: [
      "Cache must be invalidated deterministically when underlying chain data changes (reorg).",
      "Cache outputs must be reproducible from indexed sources; do not rely on ephemeral runtime state."
    ]
  },

  /**
   * User-facing guarantees (what we promise)
   */
  guarantees: [
    "moment0 is identical across all clients and all time (canonical baseline).",
    "current is stable under the declared finality policy (head - N blocks).",
    "range playback is deterministic for fixed endpoints and slicing params.",
    "Evolution never invents world state. Missing data yields explicit partial/unresolved states."
  ],

  /**
   * Non-goals / prohibitions
   */
  non_goals: [
    "No forecasting or prediction.",
    "No 'optimization' of what users should do.",
    "No hidden narrative injection in evolution frames."
  ]
} as const;

export type EvolutionContractV1 = typeof EVOLUTION_CONTRACT_V1;
```0
