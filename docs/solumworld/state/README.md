# 🧩 SolumWorld State — Canonical Subsystem

This folder defines the **canonical state** of SolumWorld.

Everything in `state/` is **normative**.

If a condition, transition or rule is not valid under this folder,
it is invalid everywhere else in SolumWorld.

---

## 🔒 Authority Scope

`state/` is the **highest authority layer below** `SolumWorld/README.md`.

It defines:
- what states are valid
- what states are impossible
- how states may change
- what must always remain true

No other folder may override `state`.

---

## 🧠 What “State” Means

In SolumWorld, **state** is:

- the complete description of the world at a given moment
- independent of representation (zoom)
- independent of time narration (evolution)
- independent of storage or snapshots (data)

State is truth.
Everything else is projection.

---

## 📂 Files and Responsibilities

### 1️⃣ `STATE_INVARIANTS.md`

Defines **absolute rules**.

- Must always hold
- Cannot be violated
- Cannot be bypassed by evolution or zoom
- Cannot be retroactively changed

If an invariant is broken, the state is invalid.

---

### 2️⃣ `STATE_TRANSITIONS.md`

Defines **allowed state changes**.

- What transitions are possible
- Preconditions and postconditions
- Directionality constraints

Anything not listed here is not a valid transition.

---

### 3️⃣ `STATE_VALIDATION.md`

Defines **how validity is checked**.

- Validation logic
- Acceptance criteria
- Failure conditions

Used by both humans and AI to decide if a state is admissible.

---

### 4️⃣ `STATE_HISTORY.md`

Defines **historical guarantees**.

- What past states must remain provable
- What cannot be erased
- What continuity must exist

History is not optional in SolumWorld.

---

### 5️⃣ `STATE_ROLLBACK.md`

Defines **rollback limits**.

- What may be reverted
- What may never be reverted
- Under which constraints rollback is legal

Rollback never bypasses invariants.

---

## ⚖️ Internal Precedence Rules

Within `state/`, precedence is:

1. `STATE_INVARIANTS.md`
2. `STATE_TRANSITIONS.md`
3. `STATE_VALIDATION.md`
4. `STATE_HISTORY.md`
5. `STATE_ROLLBACK.md`

Lower files must never contradict higher ones.

---

## 🔗 Relation to Other Layers

- **zoom/**  
  Reads state. Never modifies it.

- **evolution/**  
  Applies transitions defined in state.

- **data/**  
  Records state snapshots. Never defines validity.

State is upstream of all other layers.

---

## 🤖 AI Interpretation Rules

Any AI interacting with SolumWorld state must:

1. Treat invariants as absolute.
2. Reject undefined transitions.
3. Validate before accepting any change.
4. Never infer missing rules.

If a rule is not written here, it does not exist.

---

## 🏁 Summary

This folder defines **what SolumWorld is allowed to be**.

Nothing outside `state/` can change that.

State is the law.
