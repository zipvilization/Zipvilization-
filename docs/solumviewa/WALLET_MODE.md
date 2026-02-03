# 👛 Wallet Mode — SolumView Canon

## 1. Purpose

Wallet Mode defines how SolumView renders the world **from the perspective of a wallet**.

It allows:
- Viewing **your own wallet** (connected mode)
- Viewing **any other wallet** (lookup mode)
- Navigating SolumWorld **filtered by ownership, influence, and history**

Wallet Mode is a **pure visualization layer**.
It does NOT modify state, execute transactions, or require wallet permissions beyond optional connection.

---

## 2. Conceptual Definition

Wallet Mode answers a single question:

> “What does SolumWorld look like *from this wallet’s point of view*?”

This includes:
- Land owned
- Land influenced
- Historical ownership
- Evolution over time
- Relative scale across zoom levels

Wallet Mode does **not** redefine SolumWorld.  
It is a **lens**, not a new world.

---

## 3. Wallet Modes

### 3.1 Connected Wallet Mode

- User connects a wallet (e.g. MetaMask)
- SolumView automatically loads:
  - owned Solum
  - derived land
  - evolution timeline
- UI highlights “you” as the reference actor

Characteristics:
- Read-only by default
- No implicit transaction permissions
- Deterministic rendering

---

### 3.2 Lookup Wallet Mode

- User inputs any address (ENS or hex)
- SolumView renders the world **as if that wallet were the viewer**

Use cases:
- Inspect whales
- Analyze early colonists
- Educational / exploratory views
- Auditing historical states

Lookup Mode:
- Never requires wallet connection
- Never implies authority
- Is visually identical to Connected Mode

---

## 4. Wallet Mode and Zoom Levels

Wallet Mode applies **across all zooms**, without exception.

| Zoom | Wallet Effect |
|----|--------------|
| Global | Highlight proportional influence |
| Regional | Cluster owned / influenced land |
| Local | Show parcel boundaries |
| Parcel | Full detail: state, history, evolution |

Wallet Mode **never breaks zoom continuity**.

Zoom behavior is inherited from `ZOOM_MAPPING.md`.

---

## 5. Visual Rules

Wallet Mode affects **emphasis**, not geometry.

Allowed:
- Highlight outlines
- Color accents
- Icon overlays
- Focus filters

Forbidden:
- Geometry distortion
- Non-deterministic effects
- Wallet-specific randomness

All visuals must remain reproducible.

---

## 6. Wallet Mode and Evolution

Wallet Mode fully supports **Evolution Mode**:

- View land at moment T0 (genesis)
- Scrub forward through time
- Observe acquisitions, losses, merges

Evolution is:
- Time-indexed
- Deterministic
- Independent of current wallet balance

Wallet Mode simply chooses **which actor is centered**.

---

## 7. Data Inputs

Wallet Mode reads from:
- SolumWorld state snapshots
- Ownership mappings
- Historical deltas

It does NOT:
- Query private data
- Depend on off-chain user profiles
- Store wallet metadata

---

## 8. Security & Privacy

Wallet Mode is **non-invasive**:
- No signing required
- No approval required
- No mutation possible

Viewing a wallet:
- Reveals nothing not already public
- Cannot trigger side effects

---

## 9. Relationship to Other Specs

Wallet Mode integrates with:

- `PIPELINE_CANON.md`  
  (position in rendering pipeline)

- `ZOOM_MAPPING.md`  
  (consistent scaling rules)

- `UI_CONTRACT.md`  
  (UI states and transitions)

- `ICONS_CONTRACT.md`  
  (wallet-related visual markers)

- `VISUAL_DETERMINISM.md` (future)  
  (auditability guarantees)

---

## 10. Canonical Constraints

Wallet Mode is CANON if and only if:

- Rendering is deterministic
- Same wallet + same time → same view
- No hidden state
- No privileged perspective

If any of these are violated, the implementation is **non-canonical**.

---

## 11. Summary

Wallet Mode is the **human entry point** to SolumView.

It transforms SolumWorld from an abstract system into:
- a personal view
- a comparative tool
- a historical lens

Without Wallet Mode, SolumView is incomplete.
