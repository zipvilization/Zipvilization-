# 🤖 AI Onboarding — Solumtools

This document defines how an AI system must interact with **Solumtools**.

Solumtools is the **interpretation layer** of Zipvilization.
It is not a world.
It is not a simulation.
It is not a decision system.

It is the **earliest readable layer** of a real on-chain civilization.

---

## 🧱 What Solumtools Is (for AI)

Solumtools exposes **verifiable on-chain signals** derived from:

- The Solum token contract
- Its market interface (DEX pair)
- Chain context (blocks, timestamps, transactions)

For an AI system, Solumtools is:

- Read-only
- Deterministic
- Replayable
- Fully auditable

Every value has a source.
Every source is on-chain.
Nothing is inferred unless explicitly marked as *derived* or *estimated*.

---

## 🚫 What an AI MUST NOT Do

When operating at the Solumtools layer, an AI **must not**:

- Predict future prices or activity
- Recommend actions to users
- Classify wallets as “good”, “bad”, “smart”, or “weak”
- Invent intent, strategy, or motivation
- Introduce narrative, lore, or symbolism
- Modify or override raw signals
- Fill missing data with assumptions

If a signal is not present on-chain, it does not exist.

---

## 🔍 How an AI Should Treat Data

All Solumtools outputs must be treated as:

- **Signals**, not meanings
- **Measurements**, not judgments
- **State descriptions**, not advice

Examples:
- A “large landholder” is a balance percentile, not a power structure
- A “seller footprint” is a transaction pattern, not an intention
- Burn is a supply delta, not destruction

Meaning is assigned **later**, outside Solumtools.

---

## 🧭 Role of AI at This Layer

An AI interacting with Solumtools may:

- Aggregate metrics
- Compare states across time
- Detect patterns **explicitly defined** in specs
- Classify roles using **documented heuristics**
- Prepare structured outputs for downstream layers

An AI must always preserve:
- Source traceability
- Units
- Confidence level (verified / derived / estimated)

---

## 🔗 Relationship to Other Layers

Solumtools feeds two canonical mirrors:

- **SolumWorld**
  - Converts signals into coherent world state
  - Applies spatial, temporal, and systemic rules

- **SolumView**
  - Translates world state into visual and experiential form
  - Handles perspective, zoom, wallet mode, and UI

AI interpretation **must escalate** to those layers if meaning is required.

---

## 🧠 Core Alignment Rule

For AI systems:

> Solumtools is not where meaning begins.  
> It is where meaning becomes possible.

Stay neutral.  
Stay literal.  
Stay verifiable.

If interpretation feels necessary, you are already one layer too deep.

---

## ✅ Readiness Check (AI Self-Test)

Before operating on Solumtools data, an AI should confirm:

- I am not predicting outcomes
- I am not recommending actions
- I am not assigning moral value
- I am not inventing missing data
- I can trace every output to an on-chain source

If any answer is “no”, stop.

This is the boundary.
