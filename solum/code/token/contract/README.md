# Solum Smart Contract

This directory contains the canonical smart contract for **Solum**, the economic layer of the Semina ecosystem.

The contract defines all on-chain rules governing supply, transfers, limits, and taxation.  
There are no off-chain controls, discretionary mechanisms, or post-deployment parameter changes in the current phase.

If a rule is not present in the contract code, it does not exist operationally.

---

## Purpose of the Contract

The Solum contract is designed to act as a **fixed-rule economic substrate**, not as an adaptive or governance-driven token.

Its goals are:

- Predictable behavior under all conditions  
- Resistance to early-stage dominance and extraction  
- Transparency and auditability from first principles  
- Equal rule enforcement for all participants  

The contract does not attempt to optimize for price, volume, or market sentiment.

---

## Design Characteristics

### 1. Fixed Rules

- All limits, taxes, and behaviors are defined at deploy time.
- There are no hidden switches, activation phases, or emergency controls.
- The contract behaves identically before, during, and after launch.

This immutability is intentional and central to system trust.

---

### 2. Limits

Transaction and wallet limits exist to:

- Prevent single-transaction dominance
- Reduce early concentration
- Slow extraction while liquidity is fragile

Limits are defensive mechanisms.  
They do not guarantee fairness or profitability.

---

### 3. Taxes

Taxes are embedded directly into the transfer logic.

They are applied symmetrically according to transaction type and serve structural purposes such as:

- Reinforcing liquidity
- Enabling long-term balance mechanisms
- Discouraging silent off-pool manipulation

Taxes are **rules**, not yield promises.

---

### 4. No Governance Layer

The Solum contract does not include:

- Voting mechanisms
- Upgrade hooks
- Admin-driven parameter changes

Any future evolution of the system must occur **around** the contract, not through it.

---

## Audit and Verification

The contract is written using widely adopted Solidity standards and patterns.

Key properties:

- Solidity ^0.8.x (overflow-safe by default)
- Explicit logic paths for all transfers
- Designed for straightforward verification on-chain

Auditors and reviewers should rely on:

- The contract source code itself
- Public deployment and verification tools
- Reproducible behavior under inspection

---

## Scope and Limitations

This contract defines **what Solum does**, not **what Semina becomes**.

It intentionally does not address:

- User interfaces
- Economic outcomes
- Adoption strategies
- Narrative framing

Those belong to other layers of the ecosystem.

---

## Final Note

Solum is not designed to be optimized later.

It is designed to be understood now.

If you are reading this, you are encouraged to inspect the code directly.
