# ✅ VISUAL_DETERMINISM.md — SolumView (Canonical)

🌍 **Zipvilization is the whole.**  
🧩 **SolumWorld** defines the world-state + rules.  
👁️ **SolumView** is the *single canonical renderer* that turns SolumWorld state into visuals.

This document defines **Visual Determinism**:  
> Given the same inputs, SolumView must produce the exact same outputs (pixel-perfect, rule-perfect), across machines, across time, and across implementations.

---

## 1) What is Visual Determinism?

Visual Determinism is the guarantee that:

- **Same SolumWorld state** + **same SolumView rules** + **same seeds**  
  ➜ produces **the same rendered world**.

This is not a “nice-to-have”.  
This is the basis of:

- Trust (no hidden manipulation)
- Reproducibility (auditable outputs)
- Canon (the repo is the truth)
- Multi-client compatibility (web / desktop / future engines)

---

## 2) Why it matters in Zipvilization

Zipvilization relies on a strong principle:

> **If a rule is not written, it does not exist.**  
> If a visual cannot be reproduced, it is not canonical.

Visual determinism ensures that:
- the world cannot be “silently reinterpreted”
- the same wallet always “sees the same land”
- evolution replay is provable and consistent
- community tools can verify outputs independently

---

## 3) Scope: what MUST be deterministic

SolumView must be deterministic for:

### A) Global view outputs
- world overview tiles
- zoomed parcels
- chunk renderings
- UI state representation (minimap overlays, tags)

### B) Wallet Mode outputs
Wallet Mode must be deterministic in BOTH directions:

- **Connected wallet** view (my land)
- **Any wallet** view (lookup/search)

A wallet lookup must render the same land for everyone.

### C) Evolution Mode outputs
If you replay from “Moment 0” to “Now”, outputs must match:

- same state history
- same transition rules
- same seeds per time-step
- same rendering pipeline
- same hash checks

---

## 4) What can be allowed to vary (and how)

The only variability allowed is:

### A) Non-canonical presentation layer
Example:
- CSS layout differences
- viewport scaling on different screens
- UI skin (as long as canonical pixels are unchanged)

### B) Deterministic randomness
Randomness is allowed ONLY if:
- it is seeded deterministically
- seed sources are explicit
- seed is logged / derivable / hashable

There is **no free randomness** in Zipvilization.

---

## 5) Canonical Inputs

SolumView takes canonical inputs from:

### A) SolumWorld State
From SolumWorld docs (state/ + state model):
- parcel ownership
- world grid / tile data
- structures & upgrades
- resource distribution
- temporal markers (epoch / tick / phase)

### B) Render Rules
From SolumView docs:
- ZOOM_MAPPING.md
- ICONS_CONTRACT.md
- UI_CONTRACT.md
- PIPELINE_CANON.md

### C) Seeds
Seeds must be derived ONLY from canonical sources such as:
- world seed
- parcel id / coordinate
- epoch / tick index
- wallet address (if explicitly required)
- deterministic salt constants defined in docs

If a seed is used, its derivation must be documented.

---

## 6) Canonical Outputs

SolumView produces:

### A) Rendered tiles / frames
- chunk images
- parcel images
- map images by zoom

### B) Render metadata
A deterministic build must output metadata including:
- input hash
- rule version / commit reference
- seed(s) used
- output hash(es)

This makes every image auditable.

---

## 7) Required Determinism Guarantees

A deterministic implementation must guarantee:

### ✅ Pixel determinism
Rendered pixels must match exactly.
No floating non-determinism. No GPU “approx”.

### ✅ Rule determinism
Rules must be applied in the same order:
- same prioritization
- same collision resolution
- same icon placement order
- same UI overlay order

### ✅ Ordering determinism
Whenever something is “iterated”:
- sort keys must be defined
- tie-breaking rules must be defined
- iteration must not rely on map ordering

### ✅ Version determinism
Outputs must declare:
- which docs version they follow (commit)
- which icon contract version
- which zoom mapping version

---

## 8) The Determinism Contract

SolumView determinism is enforced by 3 layers:

### Layer 1 — Canonical Docs
This repo is the contract:
- If it’s not written, it’s not a rule.
- If it’s written, it must be reproducible.

### Layer 2 — Hashing & Verification
Every canonical output should be verifiable with:
- hash(input)
- hash(output)
- hash(ruleset)

### Layer 3 — Independent Reproduction
A third party must be able to:
- take the same state snapshot
- apply the same docs rules
- reproduce the same output

---

## 9) Deterministic Pipeline (high-level)

SolumView pipeline MUST follow a stable sequence:

1. Load canonical state snapshot (SolumWorld)
2. Resolve zoom level via ZOOM_MAPPING.md
3. Generate deterministic seeds (documented)
4. Build tile/chunk layout deterministically
5. Place icons deterministically (ICONS_CONTRACT.md)
6. Apply UI overlays deterministically (UI_CONTRACT.md)
7. Export outputs + metadata hashes

This sequence must not change silently.
If it changes, it requires a documented update + version bump.

---

## 10) Wallet Mode: determinism rules

Wallet Mode introduces a critical trust surface:
> the user must see the same parcel for the same wallet everywhere.

Wallet Mode MUST define:

- wallet lookup input (address)
- canonical parcel resolution method (from SolumWorld)
- zoom selection logic (same across clients)
- deterministic viewport framing rules

Wallet Mode must never:
- “pretty frame” in a non-deterministic way
- apply camera smoothing that changes outputs
- reorder icons based on device resolution

---

## 11) Evolution Mode: determinism rules

Evolution Mode is a deterministic replay:

### Must be defined by:
- the canonical state history format
- state transitions (SolumWorld state docs)
- deterministic “tick” logic
- deterministic seeds per tick

### Must output:
- per-tick hashes
- per-frame hashes (optional)
- a final summary hash that can be verified independently

---

## 12) Anti-drift rules (critical)

To prevent “visual drift”:

- No unversioned changes to icon meanings
- No silent changes in zoom thresholds
- No undocumented changes in seed derivation
- No “art tweaks” that change canonical pixels without update + version reference

---

## 13) Minimal Audit Checklist (10/10 standard)

A SolumView build is **deterministic** if:

- [ ] Same input snapshot renders identical outputs on 2 machines
- [ ] Hash(input) is logged
- [ ] Hash(output) is logged
- [ ] Seed derivation is documented
- [ ] Icon placement order is deterministic
- [ ] Zoom mapping is deterministic
- [ ] Wallet mode outputs are reproducible
- [ ] Evolution replay produces stable tick hashes
- [ ] Version/commit references are included in metadata
- [ ] A third party can reproduce the build with no “hidden steps”

---

## 14) Canon statement

SolumView determinism is not negotiable.

If a client cannot produce deterministic outputs:
- it is not canonical,
- it is a viewer only,
- and it cannot be used as a source of truth.

✅ Zipvilization canon = reproducible state + reproducible rendering.
