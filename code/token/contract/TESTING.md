# ✅ Testing (Foundry) — Solum Contract

This folder contains the canonical Solum contract and its Foundry test suite.

This repository is **Zipvilization-only**:
- If it is not in this repository, it is not part of the canonical build.
- If it is not deployed, it does not exist operationally.

---

## 📦 Requirements

- Foundry (forge/cast/anvil)
- Git

Install Foundry:
https://book.getfoundry.sh/getting-started/installation

Verify:
forge --version

---

## 📁 Project layout (reality)

- src/Solum.sol → canonical contract
- test/SolumToken.t.sol → canonical tests
- test/mocks/* → minimal mocks for router/pair where needed
- foundry.toml → Foundry config

---

## 🧩 Dependencies (forge-std)

This repo uses forge-std for testing utilities.

Option A (recommended for local dev): install it
From code/token/contract:

forge install foundry-rs/forge-std

Note:
forge install may create git changes inside lib/.
If you do not want to commit vendor code locally, you can discard those changes after the install:
git checkout -- lib

Option B (CI-friendly):
GitHub Actions installs dependencies as part of the workflow, so locally you only need them if you run tests on your machine.

---

## 🏗️ Build

From code/token/contract:

forge build -vvv

---

## 🧪 Run tests

From code/token/contract:

forge test -vvv

To re-run only failing tests:
forge test --rerun -vvv

---

## ✅ What tests are verifying

The canonical tests are intentionally minimal but meaningful:

- initial supply assigned to deployer
- pre-trading gate blocks non-exempt transfers
- enableTrading() is owner-only
- wallet-to-wallet transfer fee and burn behavior is validated with reflection-aware tolerance

These tests do not attempt to simulate full DEX execution.
They avoid fragile assumptions and focus on what must remain true.

---

## 🔍 Common issues

1) Identifier not found for the contract in tests  
If tests reference the wrong contract name, ensure imports match:
- ../src/Solum.sol
- contract type is Solum (not SolumToken)

2) Rounding under reflection  
Reflection introduces integer-division effects. Tests must allow minimal rounding tolerance where applicable.

3) CI failures during dependency install  
Do not use deprecated flags like forge install --no-commit.
Use plain forge install in CI and set git identity when needed.
