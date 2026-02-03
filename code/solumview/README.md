# 🎨 SolumView — Visual Contracts

**Deterministic world rendering · Read-only · Canonical**

SolumView is the **visual contract layer** of Zipvilization.

It does not interpret meaning.  
It does not access the blockchain.  
It does not modify state.

SolumView takes **validated world state** and transforms it into a
**deterministic visual representation**.

---

## 🧱 What This Folder Is

This folder contains the **canonical visual contracts** used by SolumView.

Each file defines a **strict, versioned, read-only contract** that maps
structured data into visual output.

These contracts:

- 📥 receive **validated inputs**
- 🧮 apply **pure deterministic rules**
- 🎨 output **render-ready structures**

There is **no logic duplication** and **no business rules** here.

---

## 🚫 What This Folder Is NOT

SolumView contracts do **not**:

- ❌ read from the blockchain
- ❌ infer meaning or narrative
- ❌ apply economic logic
- ❌ mutate or store state
- ❌ react to user actions

They only **render what already exists**.

---

## 🧠 Contract Design Principles

All contracts in this folder follow the same principles:

- 🔒 **Read-only**
- 🧬 **Deterministic**
- 🧾 **Versioned (`v1`)**
- 📐 **Pure functions**
- 🔗 **Composable**
- 🧪 **Testable in isolation**

Given the same input → the same output **must always be produced**.

---

## 📦 Canonical Contracts

### 🗺️ `tilemap.contract.v1.ts`
Defines the **spatial structure** of the world.

- Maps territory into tiles
- Defines grid layout and boundaries
- Produces the base world geometry

---

### 🧱 `tile-dictionary.v1.ts`
Defines the **meaning of tile types**.

- Terrain categories
- Land states
- Environmental classifications

Used by the tilemap to assign semantic tiles.

---

### 🔍 `zoom.contract.v1.ts`
Controls **level-of-detail rules**.

- Defines zoom levels
- Maps scale → visible detail
- Ensures consistent perception across views

---

### 🧬 `evolution.contract.v1.ts`
Defines **time-based visual evolution**.

- Past → present transitions
- Growth stages
- World aging rules

No simulation. Only visual progression.

---

### 👁️ `visual_determinism.contract.v1.ts`
Guarantees **reproducibility**.

- Ensures identical inputs render identically
- Locks randomness sources
- Enforces auditability

This is a **non-negotiable contract**.

---

### 🧾 `render-input.v1.ts`
Defines the **exact input schema** expected by SolumView.

- Normalized data structure
- Fully validated before rendering
- No optional ambiguity

Everything rendered must conform to this schema.

---

### 🎨 `icon_catalog.contract.v1.ts`
Maps **world state → visual symbols**.

- Icons
- Glyphs
- Visual tokens

Pure mapping. No interpretation.

---

### 🧭 `ui_tokens.contract.v1.ts`
Defines **UI-level visual tokens**.

- Colors
- Layers
- UI primitives

Shared language between rendering and interface.

---

### 👛 `walletmode.contract.v1.ts`
Defines **Wallet Mode visualization**.

- Connect own wallet
- Inspect any public wallet
- Render wallet as territory

Wallet Mode is **read-only** and **public**.

---

## 🔗 Pipeline Binding (Conceptual)

SolumTools → SolumWorld → SolumView Contracts → Renderer

- SolumTools: extract signals
- SolumWorld: define world state
- SolumView Contracts: define how it looks
- Renderer: draws pixels

Each layer is isolated.
Each layer is auditable.

---

## 🧭 Position in Zipvilization

SolumView contracts sit between:

- 🌍 **SolumWorld** — what exists
- 🖼️ **Renderer** — what is drawn

They do not decide meaning.  
They decide **form**.

---

## 🔒 Canonical Status

All contracts in this folder are:

- Canonical
- Versioned
- Immutable by convention

Any change requires:
- a new version
- explicit documentation
- full auditability

---

## ✨ Final Note

If Zipvilization is a readable civilization,  
SolumView is its **visible surface**.

Nothing more.  
Nothing less.
