/**
 * Zipvilization — SolumView
 * Pipeline Binding Contract v1 (CANONICAL)
 *
 * This contract defines how SolumWorld output
 * is bound into SolumView input WITHOUT duplicating logic.
 *
 * It is a boundary contract.
 * It does not compute.
 * It does not interpret.
 * It only declares allowed coupling.
 */

/**
 * Binding principles:
 *
 * 1. SolumView NEVER recomputes SolumWorld logic
 * 2. SolumView NEVER reads chain or Solumtools
 * 3. SolumView ONLY consumes normalized world state
 * 4. All bindings are explicit and versioned
 */

export const PIPELINE_BINDING_V1 = {
  version: "v1",

  /**
   * Upstream source
   */
  source: {
    layer: "SolumWorld",
    guarantees: [
      "state_is_normalized",
      "state_is_deterministic",
      "state_is_time_resolved",
      "no_raw_chain_data",
    ],
  },

  /**
   * Downstream target
   */
  target: {
    layer: "SolumView",
    responsibilities: [
      "pure_render",
      "zoom_projection",
      "tile_mapping",
      "ui_token_mapping",
      "visual_determinism",
    ],
  },

  /**
   * Allowed inbound domains
   */
  inbound: {
    territory_state: true,
    evolution_state: true,
    zoom_context: true,
    wallet_context: true,
    ui_state_tokens: true,
  },

  /**
   * Explicitly forbidden responsibilities
   */
  forbidden: {
    chain_reads: true,
    price_logic: true,
    tax_computation: true,
    role_classification: true,
    historical_reconstruction: true,
  },

  /**
   * Determinism guarantee
   */
  determinism: {
    input_frozen: true,
    no_side_effects: true,
    reproducible: true,
  },

  /**
   * Failure policy
   */
  failure_policy: {
    on_missing_field: "reject_render",
    on_unknown_field: "ignore",
    on_version_mismatch: "reject_render",
  },
} as const;
