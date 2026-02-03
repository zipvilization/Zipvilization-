# 🧭 SolumView (code)

SolumView is the **render contract layer** of Zipvilization.

It does not fetch chain data.
It does not interpret markets.
It does not change meaning.

SolumView does one job: **turn a verified, normalized input into a deterministic visual state**.

This folder is **implementation-facing canon**.  
The public-facing canon lives in `docs/SolumView/`.

---

## ✅ What SolumView Is

SolumView is a **pure rendering module** defined by contracts:

- It receives a **Render Input** (already normalized upstream).
- It applies **Zoom + Tile + UI + Evolution rules**.
- It outputs a **deterministic render plan** (or a deterministic UI state).

SolumView is designed so that:
- the same input → always yields the same output
- across machines, builds, and time
- with explicit versioning (`v1` contracts)

---

## 🚫 What SolumView Is NOT

SolumView is NOT:
- a chain indexer
- a pricing oracle
- a treasury dashboard
- a gameplay engine
- a simulation that “balances” reality

If a field is not present in the input, SolumView does not invent it.

---

## 📚 Canonical Specs (Docs)

SolumView code must remain coherent with:

- `docs/SolumView/README.md`
- `docs/SolumView/PIPELINE_CANON.md`
- `docs/SolumView/ZOOM_MAPPING.md`
- `docs/SolumView/ICONS_CONTRACT.md`
- `docs/SolumView/UI_CONTRACT.md`
- `docs/SolumView/WALLET_MODE.md`
- `docs/SolumView/VISUAL_DETERMINISM.md`

Docs define the rules.  
Code implements the rules.

---

## 📦 Contracts (code/solumview/contracts)

This repository currently defines the following canonical contracts:

- `render-input.v1.ts`  
  Defines the **minimum stable input surface** SolumView expects.

- `zoom.contract.v1.ts`  
  Defines zoom levels and how view parameters are derived deterministically.

- `tile-dictionary.v1.ts`  
  Defines the **tile vocabulary** (the canonical set of tiles a renderer may place).

- `tilemap.contract.v1.ts`  
  Defines how tiles are mapped/placed for a given render request.

- `icon_catalog.contract.v1.ts`  
  Defines the canonical icon set used by the UI layer.

- `ui_tokens.contract.v1.ts`  
  Defines canonical UI tokens/state codes used in the interface.

- `walletmode.contract.v1.ts`  
  Defines how Wallet Mode selects and validates a target wallet (read-only).

- `evolution.contract.v1.ts`  
  Defines Evolution Mode / time-travel rules and snapshot selection policy.

- `visual_determinism.contract.v1.ts`  
  Defines reproducibility rules and what is allowed or forbidden for determinism.

---

## 🔁 Canonical Load Order (Renderer)

A renderer/frontend should load and apply contracts in this order:

1. **Render Input** (`render-input.v1.ts`)  
   Validate that the request matches the canonical input surface.

2. **Wallet Mode** (`walletmode.contract.v1.ts`)  
   Resolve the target wallet context (connected wallet or public lookup).

3. **Evolution** (`evolution.contract.v1.ts`)  
   Resolve the time context (moment 0, snapshot, or head).

4. **Zoom** (`zoom.contract.v1.ts`)  
   Resolve view parameters and level of detail.

5. **Tile Dictionary** (`tile-dictionary.v1.ts`)  
   Load the tile vocabulary required by the tilemap.

6. **Tilemap** (`tilemap.contract.v1.ts`)  
   Produce the deterministic tile placement / render plan.

7. **UI Tokens + Icons** (`ui_tokens.contract.v1.ts`, `icon_catalog.contract.v1.ts`)  
   Map internal state codes to canonical UI representation.

8. **Visual Determinism** (`visual_determinism.contract.v1.ts`)  
   Enforce reproducibility constraints and emit audit-friendly metadata.

This order is intentional: upstream resolution (who/when/zoom) happens before placing tiles.

---

## 🧱 Determinism Rules (Non-Negotiable)

SolumView MUST:
- avoid randomness unless explicitly seeded by canonical input
- avoid device-dependent rendering paths
- avoid implicit time dependencies (must be explicit via Evolution context)
- avoid network reads inside contracts

Any renderer that consumes SolumView must be able to:
- reproduce a view by reusing the same input
- audit the outputs (inputs + contract versions + hashes)

---

## 🔒 Versioning

Contracts are versioned.

- `*.contract.v1.ts` and `*.v1.ts` are **stable v1** surfaces.
- New versions must be introduced as `v2`, without mutating `v1` behavior.

Backwards compatibility is part of the canon.

