# ⏱️ Zip Biology Timing (Canonical)
**Territory maturation = consolidated core**

This document defines how **Zip population maturity** unfolds over time as territories form and stabilize.

It is intentionally mechanical and deterministic:
- no narrative interpretation
- no off-chain assumptions
- no “death” mechanics

The goal is to establish a canonical rule-set for:
- **when** a territory becomes biologically mature,
- **how** higher-level territories activate,
- **how** maturity reacts to **upgrade / downgrade** events.

---

## 0) Definitions

### Territory level
A wallet’s territory level is defined by the **largest fully-owned unit**:
- Farm
- Village
- City
- County
- State
- Kingdom

Lower units may exist as residuals and can add *extra* smaller territory units.

### Minimum unit
The smallest unit that counts for biology is the **Farm**.

Anything below a full Farm unit is ignored for biological capacity purposes.

### Mature territory (Consolidated Core)
A territory is **mature** when its Zip population reaches its **maximum capacity** under the canonical rules of that level.

Maturity is not aesthetic.
Maturity is a biological state: **the core is consolidated**.

---

## 1) Zip Life Model (Phase-0 Canon)

### 1.1 Zip origin
Zips do not appear “born” like humans.

They appear as **sealed containers (eggs)** that:
- require a fixed time to decompress (hatch),
- then immediately become reproductively capable.

### 1.2 No death (Phase-0)
- Zips do not die.
- Population is capped only by capacity.
- Exceeding capacity does not create deaths; it prevents additional growth.

---

## 2) Core Timing Constants (initial, expressed in days)

These constants are canonical for the concept.
They can later be translated into block-based timing.

- **Hatching / decompression time:** `3 days`
- **Birth rule:** always in pairs (**twins**)

> Note: “days” are placeholders for now.  
> When integrated on-chain/off-chain, these will become block/time equivalents.

---

## 3) Reproductive Latency by Territory Level

A key concept:

> Every territory level contains **latent reproductive pairs**.  
> Those pairs are not active until the level below is mature.

### 3.1 Latent pairs count (by level)
Each territory level contains this many *latent reproductive pairs*:

- **Farm:** 1 pair (latent, activates immediately)
- **Village:** 10 pairs (latent)
- **City:** 100 pairs (latent)
- **County:** 1,000 pairs (latent)
- **State:** 5,000 pairs (latent)
- **Kingdom:** 25,000 pairs (latent)

These pairs represent the “biological nucleus” of each unit.

They activate only when allowed by maturation rules.

---

## 4) Farm Maturation Timeline (baseline)

A Farm activates immediately when it exists.

### 4.1 Farm growth logic
- At creation: 2 eggs (a pair) begin decompression
- After decompression: the pair is mature and starts laying twins
- Each cycle produces 2 eggs → 3 days → hatch → repeat

### 4.2 Farm capacity (Phase-0 baseline)
- A Farm reaches maturity when it hits its maximum Zip capacity.

(Exact capacity by territory level is defined in the companion document:
`ZIP_TERRITORY_AND_POPULATION.md`.)

### 4.3 Time to farm maturity (example logic)
Using the canonical cycle model:
- Day 3: initial pair hatches
- Then each cycle adds twins after 3 days
- A Farm becomes mature when capacity is reached

> The canonical “~16 days” farm maturity estimate is based on the initial capacity model
> and 3-day twin cycles. If the capacity model changes, this timeline updates deterministically.

---

## 5) Activation Delay for Higher Territories

Higher territories do not start reproducing at T=0.

They wait.

### 5.1 Activation rule (canonical)
A territory level activates its latent pairs only when:
1) the lower-level units required for that level are **mature**, and then
2) an additional **3 days** pass for decompression of the new level’s latent pairs.

### 5.2 Example: Village activation
A Village contains 10 latent pairs, but they remain dormant until:

- the underlying Farms needed for that Village are mature (the consolidated Farm layer), then
- **+3 days** for Village pair decompression

So, if Farms mature at ~day 16, Village reproduction begins ~day 19.

### 5.3 Same logic for all higher levels
- City activation requires mature Villages → +3 days
- County activation requires mature Cities → +3 days
- State activation requires mature Counties → +3 days
- Kingdom activation requires mature States → +3 days

This creates a consistent “biological ladder”:
**maturity below unlocks activation above**.

---

## 6) Territory Consolidation and Upgrade / Downgrade

### 6.1 Upgrade (crossing a threshold)
When a wallet crosses a threshold upward (example: `99m → 100m`):

- The territory gains a higher category (Farm → Village)
- Higher-level latent pairs become **eligible** for activation
- Activation does not happen instantly:
  - it requires the lower layer to be mature,
  - then +3 days decompression at the new level

### 6.2 Downgrade (dropping below a threshold)
When a wallet drops below a category threshold (example: `100m → 99m`):

- The higher category is lost
- Any higher-level latent pairs return to a dormant state
- The territory remains biologically consistent:
  - Zips do not die
  - growth capacity and active reproduction adjust downward
  - future re-upgrades can reactivate the ladder deterministically

### 6.3 Consolidated core interpretation
A “mature territory” is a **consolidated core**.

- Mature Farm core → stable base for Village activation
- Mature Village core → stable base for City activation
- etc.

This concept is later reusable for:
- progress systems
- building tiers
- “civilization readiness” metrics

Without changing the biological substrate.

---

## 7) Why This Timing Exists (Phase-0 Intent)

This timing model exists to ensure:

- higher territories are not “instant cities”
- large holdings still require time to consolidate biologically
- upgrades feel like structural transitions, not cosmetic labels
- downgrades have meaningful consequences without punitive death mechanics

This preserves the Zipvilization principle:

> **The world evolves from rules and time — not from narrative control.**

---

## 8) Next Document (Dependency)

This file defines timing and activation logic only.

All numeric capacity and population calculations live in:

`docs/zipvilization/Zips/ZIP_TERRITORY_AND_POPULATION.md`

---

END OF CANON
```0
