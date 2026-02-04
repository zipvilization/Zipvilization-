# 🔍 Solumtools — Observability Layer (Chapter 1)

Solumtools is the **observability layer** of Zipvilization.

Its role is simple and strict:

> **Expose what already exists on-chain, without interpretation.**

Solumtools does not create meaning.  
It does not simulate behavior.  
It does not decide roles.

It makes reality **visible, queryable, and verifiable**.

---

## 📌 Position in the System

Solumtools corresponds to **Chapter 1 — Observability**.

It sits immediately after:

- **Chapter 0 — Genesis** (`token/contract`)
  - where Solum exists as an immutable on-chain substrate

And before:

- semantic classification (roles)
- world coherence
- visual territory
- user-facing narratives

Solumtools is the **bridge between raw blockchain data and any higher layer**.

---

## 🎯 What Solumtools Does

Solumtools provides **structured access** to on-chain facts:

- Wallet balances (territory size)
- Transfers, buys, sells
- Supply and burn evolution
- Treasury inflows
- Time-based activity

All data exposed by Solumtools must be:

- directly derivable from on-chain data
- reproducible by any third party
- free of interpretation or judgment

If a signal cannot be verified on-chain, it does not belong here.

---

## 🚫 What Solumtools Does NOT Do

Solumtools deliberately avoids:

- ❌ role classification (colonist, veteran, etc.)
- ❌ scoring or ranking wallets
- ❌ visual metaphors
- ❌ progress bars or milestones
- ❌ predictions or opinions

Those belong to later chapters.

Solumtools is **pre-narrative**.

---

## 📂 Folder Intent

This folder contains the **technical machinery** required to observe Solum:

Typical components may include:
- indexers
- schemas
- canonical metrics
- API surfaces
- data normalization rules

Exact implementations may evolve, but the **scope does not**.

---

## 🧠 Design Principle

> **Transparency before meaning.**

A system that cannot be independently observed
cannot be trusted or interpreted later.

Solumtools ensures that:
- trust is earned through visibility
- understanding precedes narrative
- disagreement is possible because data is open

---

## ✅ Definition of Done (Chapter 1)

Solumtools is considered complete when:

- any wallet can be inspected
- supply and burn are visible and consistent
- transaction history is accessible
- all outputs are traceable to on-chain sources

No UI is required for completion.  
Only correctness.

---

## 🔒 Canonical Status

Everything in this folder is:

- technical
- auditable
- deterministic

If something is not observable here,
it does not exist for Zipvilization yet.
