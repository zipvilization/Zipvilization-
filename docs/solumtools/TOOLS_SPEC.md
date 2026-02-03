# 🛠️ Solumtools — Canonical Tools Specification
## Interpretation & Metrics Layer of Zipvilization (Phase 0)

Solumtools is the **interpretation and extraction layer** of the Zipvilization system.

It does not modify Solum.
It does not predict markets.
It does not provide financial advice.
It does not assign meaning beyond classification.

Solumtools has one responsibility only:

> **To extract verifiable on-chain data and expose it as a coherent, reproducible, queryable signal layer.**

If a signal cannot be derived from on-chain data, it does not exist in Solumtools.

---

## 0. Position in the System

Zipvilization is structured in three canonical layers:

- **SolumWorld** → Ontology and world rules (what exists)
- **Solumtools** → Data extraction and classification (what can be measured)
- **SolumView** → Visualization and interpretation (what is shown)

Solumtools sits strictly **between SolumWorld and SolumView**.

It never interprets meaning.
It never renders visuals.
It never introduces narrative.

It only guarantees **data truthfulness and reproducibility**.

---

## 1. Scope of Responsibility

Solumtools is responsible for:

- Reading canonical on-chain sources
- Normalizing raw blockchain data
- Classifying transactions and wallets
- Computing deterministic metrics
- Exposing stable, versioned outputs

Solumtools is NOT responsible for:

- UX decisions
- Visual metaphors
- Progress narratives
- Strategy, advice, or prediction

---

## 2. Canonical Data Sources

Solumtools may read from the following **on-chain sources only**:

1. **Solum token contract**
2. **DEX pair / liquidity pool** where SOLUM is traded
3. **Chain context** (block, timestamp, tx metadata)

If a value is not exposed on-chain, Solumtools must not invent it.

### Authoritative definitions of inputs live in:
- `INPUT_CONTRACTS.md`

---

## 3. Normalization Principles

Solumtools normalizes all data according to strict rules:

- Preserve raw on-chain values
- Provide human-readable normalized values
- Maintain deterministic unit conversions
- Never mutate historical records

All normalization schemas are defined in:
- `OUTPUT_SCHEMAS.md`

---

## 4. Indexing & Finality

Solumtools must:

- Ingest all relevant events from deployment to head
- Be reorg-aware
- Track block hashes and finality thresholds
- Distinguish between `pending` and `final` data

Correctness is always preferred over speed.

Operational flow is specified in:
- `PROCESSING_PIPELINE.md`

---

## 5. Metric Families (Conceptual)

Solumtools exposes **metric families**, not narratives.

The exact field definitions live in `OUTPUT_SCHEMAS.md`.

### 5.1 Protocol Metrics
- Supply (live / genesis / burned)
- Global activity counts
- Protocol state flags (if exposed)

### 5.2 Pool Metrics
- Reserves
- Spot price (V2-style)
- Volume and flow direction

### 5.3 Wallet Metrics
- Territory size (balance)
- Activity footprint
- Holding duration

### 5.4 Transaction Metrics
- Type classification (buy / sell / transfer)
- Volume
- Fee components (best-effort)

---

## 6. Geographic Interpretation Boundary

Solumtools may expose **geographic-equivalent values** strictly as data mappings:

- `1 Solum = 1 m²`
- Genesis supply = maximum world area
- Burned supply = permanently removed active area

Solumtools does not decide how this is visualized.
That responsibility belongs to SolumWorld and SolumView.

---

## 7. Treasury Observation (Strictly Limited)

Solumtools may observe:

- Verified on-chain inflows to the treasury address
- Correlation with protocol actions (best-effort)

Solumtools does NOT:
- Track treasury value
- Forecast spending
- Evaluate effectiveness

Treasury data is exposed as neutral inputs only.

---

## 8. Reflection Awareness (Best-effort)

Reflection effects are implicit and not directly observable.

Solumtools may estimate passive balance drift by comparing:
- Expected balance from transfers
- Actual balance over time

All reflection-related outputs must be labeled as:
- `estimated`

---

## 9. Colonist Role Classification

Solumtools may classify wallets into **roles** based solely on verifiable behavior.

Rules:
- Roles are non-exclusive
- Roles are non-moral
- Roles describe footprint, not intent

Examples of roles include:
- Veteran colonists
- Virgin territories
- Fertility contributors
- Major landholders

Exact thresholds and fields are defined in:
- `OUTPUT_SCHEMAS.md`

---

## 10. Determinism & Reproducibility

Solumtools guarantees that:

- Given the same chain state
- Using the same version
- With the same inputs

→ The outputs are identical.

This is a non-negotiable invariant.

---

## 11. Explicit Non-Goals

Solumtools does NOT:

- Recommend actions
- Predict future outcomes
- Assign value judgments
- Enforce anti-sybil guarantees
- Provide off-chain identity claims

Solumtools is an interpreter, not an oracle.

---

## 12. Phase 0 Completion Criteria

Solumtools Phase 0 is considered complete when it can:

- Ingest Solum transfers
- Ingest pool swaps and reserves
- Compute protocol, pool, and wallet metrics
- Classify roles deterministically
- Expose stable output schemas

No expansion should occur before Phase 0 is stable.
