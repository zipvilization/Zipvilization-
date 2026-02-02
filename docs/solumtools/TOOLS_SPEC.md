# 🛠️ Solumtools — Tools Specification
## Canonical on-chain data model & metrics (Phase 0)

Solumtools is the **interpretation tool layer** of Zipvilization.

It does not change Solum.
It does not predict markets.
It does not provide financial advice.

Solumtools does one job: **extract verifiable on-chain data** and expose it as a coherent, queryable set of signals.

If a signal cannot be derived from on-chain data, it does not exist in Solumtools.

---

## 0. Scope

Solumtools reads data from:

1) **Solum token contract** (ERC-20 + custom mechanics)  
2) **DEX pair / pool** where SOLUM is traded (Aerodrome V2-style pair)  
3) **Chain context** (block/time, tx metadata)

Solumtools outputs:

- protocol-level metrics (global)
- pool-level metrics (market interface)
- wallet-level metrics (colonist interface)
- transaction-level metrics (history)
- role classifications (behavioral profiles)

This spec defines the **exact data inputs** and the **metrics Solumtools must compute**.

---

## 1. Canonical Sources (On-chain)

### 1.1 Solum Contract (Token)
Required reads:
- `name()`, `symbol()`, `decimals()`
- `totalSupply()`
- `balanceOf(address)`
- `allowance(owner, spender)` (optional; UX only)

Required logs:
- `Transfer(from, to, value)`
- `Approval(owner, spender, value)` (optional)

Custom signals (if exposed by the contract):
- `tradingEnabled` (or equivalent)
- `swapBackEnabled` (or equivalent)
- `treasury` address
- `pair` address (if stored)
- emitted events such as: `TradingEnabled`, `SwapBackPaused`, `TreasuryProposed`,
  `TreasuryConfirmed`, `SwapBackConfigUpdated` (names depend on canonical contract)

> If the contract does not expose a value, Solumtools must not invent it.

---

### 1.2 DEX Pair / Pool (Aerodrome V2-style)
Required reads (pair):
- `token0()`, `token1()`
- `getReserves()` → `(reserve0, reserve1, timestampLast)`
- LP `totalSupply()` (optional, deeper analytics)

Required logs (pair):
- `Swap(...)`
- `Mint(...)`
- `Burn(...)`
- `Sync(reserve0, reserve1)` (if present)

Router reads are optional. Pair reserves are the canonical pricing primitive.

---

### 1.3 Chain Context
Required:
- `chainId`
- block number, block timestamp
- tx hash, from, to
- reorg awareness: block hash tracking and finality policy

---

## 2. Normalization Rules

### 2.1 Units
- Solum token uses `decimals = 18`.
- Normalize all amounts to:
  - **raw** (uint256)
  - **human** (decimal adjusted)
  - **Zipvilization territory**: **1 Solum = 1 m²**

### 2.2 Addresses (labels)
Solumtools must label at minimum:
- `SOLUM_CONTRACT`
- `DEX_PAIR`
- `DEX_ROUTER` (if applicable)
- `TREASURY`
- `BURN_ADDRESS` = `0x0000000000000000000000000000000000000000`

### 2.3 Transaction typing (canonical heuristic)
For each `Transfer` involving SOLUM:
- **BUY**: `from == DEX_PAIR`
- **SELL**: `to == DEX_PAIR`
- **TRANSFER**: everything else

This typing must be consistent across all metrics.

---

## 3. Indexing Strategy (Minimum Viable)

### 3.1 Required ingestion
- Ingest all SOLUM `Transfer` events from deployment block → head
- Ingest all Pair `Swap`, `Mint`, `Burn`, `Sync` from pool creation block → head

### 3.2 Reorg handling (required)
- Keep a rolling window of “unfinalized” blocks (last N blocks).
- Reprocess if block hash changes inside the window.
- Mark data as:
  - `pending`
  - `final` (past finality threshold)

Correctness > speed.

---

## 4. Core Metrics (Global)

### 4.1 Supply & Geography
- **Total Supply (live)** = `totalSupply()`
- **Genesis Supply (constant)** = `100T` Solum (from contract initial mint)
- **Burned (cumulative)** = `Genesis Supply - Total Supply`

Zipvilization mapping:
- **World size (m²)** = `Genesis Supply`
- **Active territory (m²)** = `Total Supply`
- **Permanent geography (m²)** = `Burned`  
  (interpreted as forests/rivers/lakes; not “gone” in Zipvilization)

### 4.2 Activity
From transfers:
- tx count per day/week
- BUY / SELL / TRANSFER counts
- volume by type (SOLUM)
- unique active wallets (daily/weekly)

### 4.3 Protocol state (if available)
- trading enabled (bool)
- swapback enabled (bool)
- current treasury address
- timelock pending changes (from events)

---

## 5. Pool Metrics (Market Interface)

### 5.1 Spot price (V2-style)
Let reserves map to `SOLUM` and `WETH`:
- **Spot price** = `reserveWETH / reserveSOLUM`
Expose:
- WETH per SOLUM
- SOLUM per WETH

### 5.2 Liquidity (depth proxy)
- **Pool SOLUM** = reserveSOLUM
- **Pool WETH** = reserveWETH

Zipvilization mapping:
- **Sterile land availability (m²)** = `reserveSOLUM`  
  (Solum in pool = frontier / uncolonized availability)

### 5.3 Volume
From Swap logs:
- swap count per window
- SOLUM in/out volume
- WETH in/out volume
- net flow (buy pressure vs sell pressure)

### 5.4 Slippage proxy (optional)
- reserve-based price impact estimates
- never presented as guarantees

---

## 6. Treasury Model (Protocol Resources → Progress Inputs)

Solumtools MUST NOT become a “treasury dashboard”.

Treasury metrics are limited to:
- **contract-generated inflows** (verified on-chain)
- minimal, objective accounting

### 6.1 What Solumtools tracks (allowed)
- Native ETH transfers **into the treasury address**
- Correlation to swapback transactions when possible (best-effort)

Fields:
- `treasury_inflow_eth_total`
- `treasury_inflow_eth_daily`
- `treasury_inflow_eth_weekly`
- `treasury_inflow_eth_by_tx[]` (optional)

### 6.2 What Solumtools does NOT track (non-goals)
- treasury “worth”
- treasury “forecast”
- discretionary spending plans
- ROI narratives

### 6.3 Zipvilization-facing output: Progress readiness
Solumtools may output a neutral “progress input” object:

- `progress_enabled` (bool)
- `progress_model_id` (string; references a published milestone model)
- `progress_value` (numeric; derived strictly from verified inflows)
- `progress_level` / `progress_bar` (if and only if milestones are defined publicly)

> Progress requires a defined milestone model.  
> Without a model, Solumtools outputs only raw verified inflows.

---

## 7. Reflection Metrics (Colonist Prosperity)

Reflection is implicit. Solumtools cannot “see” reflection directly.

### 7.1 Balance drift sampling
For each wallet:
- balance snapshots (daily close)
- optional snapshots after transfers

Compute:
- **passive gain estimate** =
  `balance_now - balance_expected_from_transfers`

Label as:
- `estimated`
- not exact attribution

Zipvilization mapping:
- organic prosperity / silent expansion

---

## 8. Fees & Interpretation (Best-effort)

Solumtools must not assume fees unless:
- fee constants are known (from Solum CONTRACT_SPEC)
- tx type is known (buy/sell/transfer)

Per tx compute expected components:
- burn
- liquidity
- treasury
- reflection
- net received

Validate when possible:
- burn as `Transfer(_, 0x0, amount)` + reduced `totalSupply`
- contract fee accumulation as `Transfer(_, SOLUM_CONTRACT, amount)` (if implemented)

Zipvilization mapping (handled in translation docs, not here):
- burn → permanent geography
- LP → frontier stability
- treasury → evolution capacity
- reflection → prosperity
- transfer tax → relocation cost

---

## 9. Colonist (Wallet) Profile Metrics

For any wallet `A`:

### 9.1 Territory
- **Territory (m²)** = `balanceOf(A)` (human units)
- **Territory delta** over time
- optional: percentile rank

### 9.2 Activity footprint
- counts: buys/sells/transfers
- last activity time
- net inflow/outflow (SOLUM)
- estimated movement cost (fees; best-effort)

### 9.3 Frontier interaction
- acquisitions from pool (buys)
- disposals to pool (sells)

---

## 10. Colonist Roles (Canonical Classification)

Solumtools classifies **roles** using verifiable behavior.

Important rules:
- Roles are not moral labels.
- No “bad actors” concept exists in Solumtools.
- A role describes a footprint. Zipvilization interprets the footprint as world function.

A wallet may have multiple roles.

### 10.1 Veteran Colonists
Definition (minimum viable):
- `first_seen_block` / `first_seen_time` early in history
- OR `holding_duration_days` above a threshold

Outputs:
- `role_veteran = true`
- `veteran_since` (timestamp)

### 10.2 Virgin Territories (No-Operation Colonists)
Definition:
- wallet holds SOLUM
- and has **no outgoing transfers** since first acquisition
- optionally: no sells; no transfers out

Outputs:
- `role_virgin = true`
- `virgin_since` (timestamp)

### 10.3 Fertility / Reflection Contributors (Seller Footprint)
In Zipvilization, sells are not “bad”. They are part of the system:
- sells typically trigger higher fee paths (burn + reflection + LP + treasury)

Definition (technical):
- top wallets by **cumulative sold volume** to pair
- and/or top wallets by **estimated burn+reflection contribution** (best-effort)

Outputs:
- `role_fertility_contributor = true`
- `sold_volume_total`
- `estimated_burn_contribution`
- `estimated_reflection_contribution`

### 10.4 Largest Landholders (Territory Size)
Definition:
- top wallets by current `balanceOf(A)`

Outputs:
- `role_major_landholder = true`
- `territory_m2`

### 10.5 Role scoring (optional)
Solumtools may expose role scores 0..100 based on rank percentile:
- `veteran_score`
- `virgin_score`
- `fertility_score`
- `landholder_score`

Scores must be explicitly defined and reproducible.

---

## 11. Public Output Surfaces (Data API)

Minimal stable endpoints:
- `/protocol/summary`
- `/pool/summary`
- `/wallet/:address/summary`
- `/wallet/:address/roles`
- `/tx/:hash/details`
- `/timeseries/{metric}?window=...`

Every field includes:
- unit
- source type (contract read / event / derived)
- confidence (verified / derived / estimated)

---

## 12. Non-goals (Explicit)

Solumtools does NOT:
- recommend actions
- predict future price/volume
- invent off-chain identity claims
- claim anti-sybil guarantees
- present moral judgments

Solumtools is an interpreter.

---

## 13. Phase 0 Deliverables Checklist

Minimum “green” state:
- ingest SOLUM transfers
- ingest pair swaps/reserves
- compute:
  - supply / burned / world size
  - pool reserves + spot price
  - treasury verified inflows
  - per-wallet territory + history
  - role classification
- publish stable JSON endpoints (or static snapshots)

Only after this is stable should Solumtools expand into richer interpretations.
