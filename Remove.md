# 🔗 Pipeline Binding — Canonical (v1)

This document defines how **SolumWorld → SolumView** are connected.

There is exactly **one valid pipeline**.

No shortcuts.  
No duplicated logic.  
No hidden computation.

---

## 1. Purpose

The pipeline exists to ensure that:

- SolumWorld remains the **only source of world interpretation**
- SolumView remains a **pure, deterministic rendering layer**
- No business logic is reimplemented at the visual level

SolumView never interprets.  
It only renders what is explicitly provided.

---

## 2. Canonical Binding Contract

The only allowed binding is: pipeline.binding.v1.ts

This binding defines:
- which fields SolumView may consume
- the exact structure of visual input
- immutable constraints on interpretation

If a value is not present in the binding:
→ it **does not exist** for SolumView.

---

## 3. What SolumView Can Do

SolumView may:
- select visual assets
- map values to tiles
- apply zoom rules
- render timelines
- display wallet territories

All of this is **pure transformation**, never interpretation.

---

## 4. What SolumView Cannot Do

SolumView must never:
- read Solumtools directly
- read on-chain data
- recompute balances
- infer missing values
- apply economic or behavioral logic

Any of the above breaks determinism.

---

## 5. Determinism Guarantee

Given:
- the same SolumWorld state
- the same binding contract
- the same versioned assets

SolumView must always render:
- the same output
- on any machine
- at any time

This is a non-negotiable rule.

---

## 6. Canonical Enforcement

Any visualization that:
- bypasses the pipeline
- injects new logic
- derives extra meaning

is **non-canonical** and must not be shipped.

---

## 7. Summary

SolumWorld decides **what exists**.  
SolumView decides **how it looks**.

The pipeline guarantees that this boundary is never crossed.
