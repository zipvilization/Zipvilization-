# Testing (Foundry)

This folder includes a Foundry test suite for `SolumToken.sol`.

## Requirements
- Foundry (forge)

## Install test dependency (local, not committed)
From this folder:

cd code/token/contract
forge install foundry-rs/forge-std --no-commit

## Run tests
forge test -vv

More verbosity:
forge test -vvvv

## What is covered
The test suite validates:

- Real burn on sells reduces totalSupply by the expected burn amount
- Reflection increases passive holder balances after taxed sells
- swapBack triggers on sells and pays ETH to the treasury (using mocks)
- freezeConfig() (Option A) prevents further config/exemption edits

## Notes
- Router and pair are mocked for deterministic testing.
- A real Base/Aerodrome fork test can be added later to validate router compatibility on-chain.
