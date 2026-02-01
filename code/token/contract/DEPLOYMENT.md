# Deployment Notes (Base + Aerodrome)

This document describes the minimum required inputs and post-deploy steps for `SolumToken.sol`.

## Constructor parameters

The contract is deployed by injecting the DEX integration addresses:

- `router`: the Aerodrome-compatible router used for swaps / liquidity actions
- `pair`: the pool pair address for SOLUM/WETH (or the chosen base asset)
- `weth`: the network wrapped native token address (WETH on Base)
- `treasury`: the treasury recipient address

**Important:** The `pair` address must match the actual pool used for trading, because buy/sell detection relies on `from == pair` and `to == pair`.

## Post-deploy toggles

- Trading is disabled by default.
- The owner must call `enableTrading()` to allow public transfers and DEX trading.
- swapBack can be paused/unpaused via the owner control function.

## SwapBack configuration

SwapBack is protected by:
- swap threshold
- cooldown
- max tokens swapped per execution
- best-effort slippage guard (when router quoting is available)

These parameters can be tuned using the contract admin configuration function.
