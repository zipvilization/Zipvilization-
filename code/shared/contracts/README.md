# shared/contracts

This folder is **NOT** the Solum contract.

It exists only to provide **developer-facing artifacts** used by the off-chain stack:
- Interfaces (`I*.sol`) for compile-time typing
- Optional ABI JSON files (when generated)
- Optional address maps (when deployment exists)

## ✅ Source of truth

The **only canonical Solum implementation** lives here:

- `code/token/contract/src/Solum.sol`

If a rule is not present in that file, it does not exist on-chain.

## 🚫 Hard rule (no duplicate logic)

This folder must never contain:
- a second copy of the Solum implementation
- “core” variants
- modified versions of Solum
- partial implementations that can be confused with the real contract

Interfaces only.
