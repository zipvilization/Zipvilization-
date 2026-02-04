# Solum (SOLUM) — Canonical Contract Specification (Zipvilization)

## 0) Scope

This document describes **all on-chain rules** of the canonical `Solum.sol` contract (Solidity `^0.8.20`).

- Source of truth: the contract code.
- Purpose: make the system auditable and unambiguous for both developers and AI.
- If a rule is not in the contract, it does not exist operationally.

---

## 1) Token Identity (Metadata)

```solidity
string public constant name = "Solum";
string public constant symbol = "SOLUM";
uint8 public constant decimals = 18;
```

---

## 2) Supply: Fixed, With Real Burn (True Deflation)

### 2.1 Initial Supply (100T)

```solidity
uint256 private _tTotal = 100_000_000_000_000 * 10**decimals; // 100T
```

- No mint path exists (no `mint`, `ownerMint`, or inflation switch).
- Supply can only decrease through real burn.

### 2.2 Dual-supply (Reflection Base)

```solidity
uint256 private _rTotal = type(uint256).max - (type(uint256).max % _tTotal);
mapping(address => uint256) private _rOwned;
```

- `_tTotal` is the “real” supply users see.
- `_rTotal` and `_rOwned` are internal reflected balances enabling passive redistribution without claim/staking.

### 2.3 Real Burn: reduces `_tTotal` (and `_rTotal` proportionally)

Within `_transfer`:

```solidity
_tTotal -= tBurn;
_rTotal -= tBurn * rate;
emit Transfer(from, address(0), tBurn);
```

This is real burn because totalSupply decreases (not just a transfer to a “dead wallet”).

---

## 3) ERC-20 Standard Functions + Reflection Conversions

### 3.1 totalSupply()

```solidity
function totalSupply() external view returns (uint256) { return _tTotal; }
```

### 3.2 balanceOf()

```solidity
function balanceOf(address account) public view returns (uint256) {
    return tokenFromReflection(_rOwned[account]);
}
```

### 3.3 tokenFromReflection() and rate

```solidity
function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    uint256 currentRate = _getRate();
    return rAmount / currentRate;
}

function _getRate() internal view returns (uint256) {
    return _rTotal / _tTotal;
}
```

---

## 4) Denominators (Fees & Slippage)

```solidity
uint256 private constant FEE_DENOM = 1_000_000; // ppm fees
uint256 private constant BPS_DENOM = 10_000;    // basis points
```

- Fees are expressed in ppm (1,000,000 = 100%).
- Slippage uses bps (10,000 = 100%).

---

## 5) Taxes: Transaction-Type Totals + Deterministic Split

This contract uses **total fees per tx type** (buy/sell/transfer), plus hardcoded split rules.

### 5.1 Fee Totals (initial values)

```solidity
uint256 public constant BUY_FEE_INITIAL = 10_000;      // 1.0%
uint256 public constant SELL_FEE_INITIAL = 100_000;    // 10.0%
uint256 public constant TRANSFER_FEE_INITIAL = 50_000; // 5.0%

uint256 public buyFeeTotal;
uint256 public sellFeeTotal;
uint256 public transferFeeTotal;
```

### 5.2 BUY fee split: 50% LP / 50% Treasury

Representative logic:

```solidity
uint256 tBuyFee = (tAmount * buyFeeTotal) / FEE_DENOM;
tLP = tBuyFee / 2;
tTreasury = tBuyFee - tLP;
```

### 5.3 SELL fee split: 4/3/2/1 (Burn/Reflection/LP/Treasury) as 10 parts

Representative logic:

```solidity
uint256 tSellFee = (tAmount * sellFeeTotal) / FEE_DENOM;
tBurn = (tSellFee * 4) / 10;
tReflection = (tSellFee * 3) / 10;
tLP = (tSellFee * 2) / 10;
tTreasury = tSellFee - tBurn - tReflection - tLP;
```

### 5.4 TRANSFER fee split: 2/3 (Burn/Reflection) as 5 parts

Representative logic:

```solidity
uint256 tTransferFee = (tAmount * transferFeeTotal) / FEE_DENOM;
tBurn = (tTransferFee * 2) / 5;
tReflection = tTransferFee - tBurn;
```

---

## 6) Fee Governance: Only-Decreasing, 24h Timelock, Max 5 Changes, Auto-Freeze

### 6.1 Timelock

```solidity
uint256 public constant FEE_TIMELOCK = 24 hours;
```

Each fee type has:
- pending value
- available-at timestamp
- changes-used counter
- frozen flag

Example (BUY):

```solidity
uint256 public pendingBuyFeeTotal;
uint256 public buyFeeChangeTime;
uint8 public buyFeeChangesUsed;
bool public buyFeeFrozen;
```

(Similar fields exist for SELL and TRANSFER.)

### 6.2 Only-decreasing rule

Proposals must satisfy:

```solidity
require(newTotalFee <= buyFeeTotal, "ONLY_DECREASING");
```

(Analogous for SELL/TRANSFER.)

### 6.3 Max changes: 5

Each fee can be reduced **up to 5 times**. It auto-freezes when:
- the fee reaches 0, or
- changes used reaches 5.

Representative behavior:

```solidity
changesUsed++;
if (feeTotal == 0 || changesUsed >= FEE_MAX_CHANGES) {
    feeFrozen = true;
}
```

### 6.4 Exact flow

For each fee type:
1) `propose*FeeReduction(newTotalFee)` → sets pending value + `FEE_TIMELOCK`
2) wait `FEE_TIMELOCK`
3) `confirm*FeeReduction()` → applies, increments counter, may freeze

Events provide audit trace:
- `*FeeProposed(newFee, availableAt)`
- `*FeeApplied(newFee, changesUsed)`
- `*FeeFrozen(changesUsed)`

---

## 7) Trading Gate (Pre-Trading Discipline)

### 7.1 State

```solidity
bool public tradingEnabled = false;
```

### 7.2 One-time activation (owner-only)

```solidity
function enableTrading() external onlyOwner {
    require(!tradingEnabled, "TRADING_ON");
    tradingEnabled = true;
    emit TradingEnabled();
}
```

### 7.3 Pre-trading restriction

```solidity
if (!tradingEnabled) {
    require(isFeeExempt[from] || isFeeExempt[to], "TRADING_OFF");
}
```

---

## 8) Anti-Whale: MAX_TX + Dynamic MAX_WALLET

### 8.1 MAX_TX (fixed 10B)

```solidity
uint256 public constant MAX_TX_AMOUNT = 10_000_000_000 * 10**decimals; // 10B
```

Enforced as:

```solidity
if (!isLimitExempt[from] && !isLimitExempt[to]) {
    require(tAmount <= MAX_TX_AMOUNT, "MAX_TX");
}
```

### 8.2 Dynamic MAX_WALLET

Constants:

```solidity
uint256 public constant MAX_WALLET_INITIAL = 30_000_000_000 * 10**decimals; // 30B
uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;
uint256 public constant MAX_WALLET_WEEKLY_GROWTH_PPM = 110_000; // +10% weekly
```

Core behavior:
- strict limit for the first 180 days
- then weekly compounding growth
- safety cap to avoid unbounded loops; beyond a horizon it becomes effectively uncapped

Applied on receive:

```solidity
if (!isLimitExempt[to] && to != pair && to != router) {
    uint256 newBal = balanceOf(to) + tAmount;
    require(newBal <= _maxWalletNow(), "MAX_WALLET");
}
```

---

## 9) Treasury: Address + Timelocked Change

```solidity
address public treasury;
address public pendingTreasury;
uint256 public treasuryChangeTime;
uint256 public constant TREASURY_CHANGE_DELAY = 48 hours;
```

### Propose / Confirm flow

```solidity
function proposeTreasury(address newTreasury) external onlyOwner {
    pendingTreasury = newTreasury;
    treasuryChangeTime = block.timestamp + TREASURY_CHANGE_DELAY;
    emit TreasuryProposed(newTreasury, treasuryChangeTime);
}

function confirmTreasury() external onlyOwner {
    require(block.timestamp >= treasuryChangeTime, "TIMELOCK");
    treasury = pendingTreasury;
    pendingTreasury = address(0);
    treasuryChangeTime = 0;

    isFeeExempt[treasury] = true;
    isLimitExempt[treasury] = true;

    emit TreasuryConfirmed(treasury);
}
```

---

## 10) DEX Wiring (router/pair/weth)

```solidity
address public immutable router;
address public immutable pair;
address public immutable weth;
```

- Router and pair are injected at deploy.
- `weth` is read from the router’s `WETH()`.

The contract expects a V2-style router compatible with:
- `swapExactTokensForETHSupportingFeeOnTransferTokens`
- `addLiquidityETH`
- `getAmountsOut` (best-effort; if unavailable the contract falls back safely)

---

## 11) SwapBack: Threshold, Cooldown, Caps, Slippage (MEV-aware)

### 11.1 Public controls

```solidity
bool public swapBackEnabled = true;

uint256 public swapThreshold;
uint256 public swapBackMaxAmount;
uint256 public swapBackCooldown;
uint256 public slippageBps;

uint256 public lastSwapBackTime;
```

### 11.2 Owner guardrails for config

- slippage bounded (e.g., 50..800 bps)
- maxAmount >= threshold
- cooldown bounded (e.g., <= 15 minutes)

### 11.3 Fee buckets

```solidity
uint256 private _tokensForLiquidity;
uint256 private _tokensForTreasury;
```

Buckets increase during fee collection, then are processed in `_swapBack()`.

### 11.4 Trigger conditions (sells only)

`_swapBack()` is triggered primarily on sells (`to == pair`), with cooldown and threshold checks.

### 11.5 Best-effort minOut with slippage

The contract attempts `getAmountsOut`; if unavailable, minOut becomes 0.
This avoids DoS across different router implementations while still applying:
- cooldown
- threshold
- per-swap cap

### 11.6 Liquidity + Treasury ETH routing

SwapBack:
- swaps a portion to ETH
- adds liquidity (token + ETH)
- sends remaining ETH to treasury

LP tokens are typically minted to a specific recipient (often `owner`), enabling external locking.

---

## 12) Launch Access Controls (Whitelist + Buy Cooldown, Phase-0 Only)

These rules exist **only to stabilize the first 48 hours** after trading is enabled.

They are designed to:
- prevent rapid buy-looping during the most hostile phase,
- provide a short, explicit preference window to an early-access set,
- keep the privilege limited to **MAX_TX only** (not MAX_WALLET),
- keep sells always possible (no exit restrictions).

### 12.1 Launch window duration (48h)

- The contract defines a launch window starting at the moment trading is enabled.
- For the first **48 hours**, extra buy rules apply.
- After the window expires, these extra buy rules are inactive.

### 12.2 Whitelist preference window (first 60 minutes)

- For the first **60 minutes** after trading is enabled:
  - only **whitelisted** addresses are allowed to buy from the pool (pair).
  - buys are still capped by `MAX_TX_AMOUNT`.
- This is a preference window, not a special allocation.

### 12.3 Per-wallet buy cooldown (60 minutes)

During the same 48h launch window:

- A wallet may execute a buy (from the pair) **at most once per 60 minutes**.
- This applies to:
  - whitelisted wallets during the first hour
  - all wallets after the first hour (public phase)

Cooldown rules apply **only to buys**.
Sells and normal transfers are not blocked by cooldown.

> Canonical intent: “buy privilege = time to enter once”, not “ability to accumulate”.

### 12.4 Max buy = MAX_TX (no special maxWallet)

Whitelist preference does not bypass:
- `MAX_TX_AMOUNT` (it is the *only* allowed purchase size for fair entry; equal or lower).

Whitelist preference does not change:
- `MAX_WALLET` rules (still enforced).

---

## 13) Exemptions (fees & limits)

```solidity
mapping(address => bool) public isFeeExempt;
mapping(address => bool) public isLimitExempt;
```

Initial exemptions typically include deployer, contract, treasury, router, pair.

Owner can update exemptions:

```solidity
function setFeeExempt(address account, bool exempt) external onlyOwner;
function setLimitExempt(address account, bool exempt) external onlyOwner;
```

---

## 14) Ownership

A minimal Ownable pattern is embedded:
- `owner`
- `onlyOwner`
- `transferOwnership(newOwner)`

---

## 15) Events (Audit Trace)

Core events include:
- ERC20: `Transfer`, `Approval`
- Launch: `TradingEnabled`
- SwapBack: `SwapBackPaused`, `SwapBackConfigUpdated`
- Treasury: `TreasuryProposed`, `TreasuryConfirmed`
- Fee governance: `*FeeProposed`, `*FeeApplied`, `*FeeFrozen`
- Ownership: `OwnershipTransferred`

If launch access controls have explicit events (recommended):
- whitelist updates (address added/removed)
- launch window parameters (if configurable at deploy)

---

## 16) ETH handling

The contract can receive ETH (swap proceeds / liquidity operations):

```solidity
receive() external payable {}
```

---

## 17) What can change vs what cannot

### Immutable / cannot increase
- Supply cannot increase (no mint).
- MAX_TX fixed (10B).
- MaxWallet growth rules are hardcoded.

### Changeable with hard constraints
- Fee totals (buy/sell/transfer): only-decreasing, 24h timelock, max 5 changes each, auto-freeze.
- SwapBack parameters: bounded by guardrails.
- Treasury: timelocked change.
- Exemption lists: owner-controlled.
- Launch access controls: fixed Phase-0 posture (48h window, 60m whitelist preference, 60m cooldown) unless explicitly coded otherwise.

---

## 18) Zipvilization interpretation (no denial of blockchain reality)

- On-chain: holders, transfers, market activity are real.
- Zipvilization layer: holders are interpreted as colonists; balances as territory.
- Fees and protections are structural mechanics:
  - defend early-phase liquidity
  - reduce shock extraction
  - reward holding via reflection
  - fund evolution via treasury

---

END OF SPEC
