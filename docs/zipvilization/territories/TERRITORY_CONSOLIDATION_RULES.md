# 🧱 Territory Consolidation Rules (Canonical)
**Pure math — no biology, no visuals, no interpretation**

This document defines how a wallet’s Solum balance is **decomposed into territories** and how **rank (tier) is assigned**.

- **Input:** on-chain `balanceOf(wallet)` in Solum units (human units)
- **Output:** a deterministic structure:
  - `primary_tier` (highest tier owned)
  - counts of consolidated units (farm/village/city/county/state/kingdom)
  - residual handling (discard rules)
  - promotion/demotion rules as balance changes

If a rule is not defined here, it does not exist.

---

## 0) Canonical Units & Tiers

> Solum is measured in **millions** for territory thresholds.

| Tier | Name (EN) | Threshold (Solum) | Shorthand |
|---:|---|---:|---|
| T1 | Farm | 10M | 10M |
| T2 | Village | 100M | 100M |
| T3 | City | 1,000M | 1B |
| T4 | County | 10,000M | 10B |
| T5 | State | 50,000M | 50B |
| T6 | Kingdom | 250,000M | 250B |

### 0.1 Composition ratios (canonical)
These are *structural* relationships, not optional.

- **1 Village = 10 Farms**
- **1 City = 10 Villages = 100 Farms**
- **1 County = 10 Cities = 100 Villages = 1,000 Farms**
- **1 State = 5 Counties = 50 Cities = 500 Villages = 5,000 Farms**
- **1 Kingdom = 5 States = 25 Counties = 250 Cities = 2,500 Villages = 25,000 Farms**

> Note the only non-10 ratio is **State** and **Kingdom** (×5).

---

## 1) The Core Rule: “Highest Tier Wins”
A wallet’s **territory name** is the highest tier that has at least one consolidated unit.

Example:
- A wallet with `1,114M` is a **City** (because it has ≥ 1,000M).
- A wallet with `99M` is a **Farm** (because it has < 100M).

---

## 2) Deterministic Decomposition (Greedy, Top-Down)

Given balance `B` (in Solum), compute:

1) `kingdoms = floor(B / 250,000M)`; `B = B % 250,000M`
2) `states   = floor(B / 50,000M)`;  `B = B % 50,000M`
3) `counties = floor(B / 10,000M)`;  `B = B % 10,000M`
4) `cities   = floor(B / 1,000M)`;   `B = B % 1,000M`
5) `villages = floor(B / 100M)`;     `B = B % 100M`
6) `farms    = floor(B / 10M)`;      `B = B % 10M`
7) `residual = B` (anything < 10M)

### 2.1 Residual rule (discard)
Any remainder `< 10M` is **not represented as territory**.

- Residual **does not create** farms.
- Residual **does not change** tier naming (except by crossing thresholds).

Residual is still real Solum on-chain.
It simply has no minimum unit representation in Zipvilization.

---

## 3) Promotion & Demotion (Tier changes)

Tier changes are automatic and reversible.

### 3.1 Promotion (example)
- `99M → 100M` : Farm → Village  
- `999M → 1,000M` : Village → City  
- `9,999M → 10,000M` : City → County  
- `49,999M → 50,000M` : County → State  
- `249,999M → 250,000M` : State → Kingdom

### 3.2 Demotion (example)
If a wallet falls below the tier threshold, it **immediately** loses that tier.

- `100M → 99M` : Village → Farm  
- `1,000M → 999M` : City → Village  
…and so on.

> Demotion is not punishment. It is deterministic classification.

---

## 4) “Consolidated core” vs “extensions”
For any wallet:

- The **core** is the largest consolidated tier unit(s) it owns.
- The **extensions** are the lower-tier units remaining after decomposition.

Example:
- `B = 1,335M`
  - `cities = 1` (core)
  - remaining `335M` decomposes into:
    - `villages = 3`
    - `farms = 3`
    - `residual = 5M` (discard)

The wallet is named **City** (highest tier present).

---

## 5) Acquisition constraint (MAX_TX reality)
In Solum, direct acquisition from the pool is bounded by **MAX_TX**.

**Canonical rule:**
- Up to **10B** (County threshold) is *directly* reachable by repeated buys (subject to launch rules).
- **State** and **Kingdom** levels typically require consolidation via transfers across wallets (or long-term accumulation).

> This document defines classification only.  
> The economic cost of consolidation (tax on transfers) is defined by the contract and surfaced by Solumtools.

---

## 6) Output schema (Solumtools-facing)
A minimal deterministic output:

```json
{
  "balance_m": 0,
  "primary_tier": "farm|village|city|county|state|kingdom|none",
  "units": {
    "farms": 0,
    "villages": 0,
    "cities": 0,
    "counties": 0,
    "states": 0,
    "kingdoms": 0
  },
  "residual_m": 0
}
```

Notes:
- `balance_m` and `residual_m` are expressed in **millions** for readability in this layer.
- `primary_tier = none` only if `balance < 10M`.

---

## 7) Examples (canonical)

### Example A — 87M
- `villages = 0`
- `farms = floor(87/10)=8`
- `residual = 7M`
- **primary_tier: Farm**

### Example B — 104M
- `villages = 1` (100M)
- remaining `4M` residual
- `farms = 0`
- **primary_tier: Village**
- **Note:** residual does not create extra farms.

### Example C — 1,114M
- `cities = 1` (1,000M)
- remaining `114M`:
  - `villages = 1` (100M)
  - `farms = 1` (10M)
  - `residual = 4M`
- **primary_tier: City**
- Units: `1 city, 1 village, 1 farm`

### Example D — 12,345M
- `counties = 1` (10,000M)
- remaining `2,345M`:
  - `cities = 2` (2,000M)
  - remaining `345M`:
    - `villages = 3` (300M)
    - `farms = 4` (40M)
    - `residual = 5M`
- **primary_tier: County**

### Example E — 52,010M
- `states = 1` (50,000M)
- remaining `2,010M`:
  - `cities = 2` (2,000M)
  - `farms = 1` (10M)
  - `residual = 0`
- **primary_tier: State**

---

## 8) Canonical boundaries & non-goals
This document does NOT define:
- population
- Zip biology
- buildings
- progress
- UI rendering

It only defines **math and classification**.

---

END OF CANON
