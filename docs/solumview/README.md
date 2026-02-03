# 👁️ SolumView — Technical Canon

**SolumView is Zipvilization’s final visual layer.**  
It renders **SolumWorld state** into a deterministic, auditable view — without inventing rules, data, or meaning.

> 🌍 Zipvilization = the whole  
> 🧩 SolumWorld = state + rules  
> 👁️ SolumView = canonical renderer

---

## ✅ What SolumView Is

SolumView is a **state-to-visual projection system**.

It takes inputs that already exist (or are already computed) in the stack:

- **Solum (on-chain)** → immutable signals (supply, transfers, pool primitives)
- **Solumtools (off-chain interpreter)** → normalized metrics + derived signals (no invention)
- **SolumWorld (world layer)** → canonical world-state, zoom rules, evolution mode, state model
- **SolumView (this folder)** → the **visual expression** of that state

SolumView does **not**:
- simulate a world
- decide what reality is
- add narrative meaning
- change economics
- “make it pretty” at the cost of truth

It only makes the world **visible**.

---

## 🎯 Core Requirement: Visual Determinism

SolumView must be **reproducible**.

**Same inputs ⇒ same outputs (pixel-perfect / rule-perfect).**

That means:
- no hidden randomness
- no device-specific layout drift
- no subjective rendering choices
- no “best effort” visualization

When something changes visually, it must be explainable by a change in:
- on-chain Solum state,
- Solumtools-derived signals,
- SolumWorld rules/state,
- or the explicit SolumView contract documents in this folder.

---

## 🧭 Canonical Document Map

This folder defines the minimum canonical surface for SolumView:

### 1) 🧱 Canonical pipeline (how we render)
- **PIPELINE_CANON.md** — the end-to-end rendering pipeline:
  input acquisition → normalization → state binding → view output.

### 2) 🔎 Zoom mapping (how SolumWorld zoom becomes visible)
- **ZOOM_MAPPING.md** — mapping between SolumWorld zoom levels and SolumView visual zooms.
  Zoom in SolumView is not a camera trick — it is a **semantic resolution selector**.

### 3) 🧩 UI contract (what the UI must expose)
- **UI_CONTRACT.md** — canonical UI structure, panels, disclosure rules, and non-negotiable visibility.
  UI is state-first, not presentation-first.

### 4) 🧿 Icons contract (visual semantics)
- **ICONS_CONTRACT.md** — every icon is a **semantic state encoder**.
  No decorative icons. No ambiguous symbols.

### 5) ✅ Visual determinism (auditability)
- **VISUAL_DETERMINISM.md** — reproducibility rules, hashing strategy, validation expectations.

### 6) 👛 Wallet Mode (viewer perspective)
- **WALLET_MODE.md** — view any wallet (lookup) or your own (connect), as a **visual filter** over SolumWorld.
  Wallet Mode does not change state; it changes *perspective*.

### 7) 🤖 AI onboarding (how an AI must read this folder)
- **AI_ONBOARDING.md** — operating rules for an AI agent implementing SolumView.
  (How to read hierarchy, how to avoid inventing, how to stay deterministic.)

---

## 🧩 Relationship to SolumWorld

SolumWorld is the **source of truth** for:
- world-state model
- zoom rules
- evolution mode
- state transitions and invariants
- any rule that defines “what exists”

SolumView is the **source of truth** for:
- how that state becomes visible
- which UI elements are allowed/required
- icon semantics
- determinism guarantees and validation

**If SolumWorld doesn’t define it, SolumView must not render it.**  
**If SolumView renders it, it must be traceable to SolumWorld.**

---

## 🧱 Minimal Implementation Targets

A SolumView implementation is considered “green” when it can:

- Render a given SolumWorld snapshot deterministically
- Render the same snapshot identically across machines
- Produce a validation hash (or manifest) for verification
- Support semantic zoom switching (via ZOOM_MAPPING)
- Support Wallet Mode perspective filtering (via WALLET_MODE)
- Use icons strictly by ICONS_CONTRACT
- Respect UI disclosure rules in UI_CONTRACT

---

## 📌 Canon Rule

If a behavior is not explicitly defined in:
- **SolumWorld canon**, or
- **SolumView canon (this folder)**

…then that behavior does not exist as canon.

No hidden rules. No silent assumptions.
