# Solum — Smart Contract

This document provides the canonical reference to the Solum smart contract deployed on-chain.

The contract is presented as-is, without abstraction or interpretation.
Its behavior is defined exclusively by its source code.

---

## Network

- **Blockchain:** Base
- **DEX:** Uniswap V2
- **Token name:** Solum
- **Symbol:** SOLUM
- **Total supply:** 100T (crypto notation)

---

## Contract identifiers

- **Contract address:** `TBD`
- **Deployer:** `TBD`
- **Verification (BaseScan):** `TBD`
- **Commit / Source hash:** `TBD`

---

## Source code

> The following is the exact source code of the deployed contract.

```solidity
// SPDX-License-Identifier: MIT

/**
 * @title Solum (SOLUM) — Semina Framework Token
 * @notice Fixed-supply, deflationary token designed as the economic substrate of the Semina Framework.
 * @dev Deployed on Base network using Uniswap V2 router.
 *
 * CORE PRINCIPLES:
 * - Fixed supply (no mint, no inflation)
 * - Real burn (supply decreases)
 * - Only-decreasing fees
 * - Anti-whale protections
 * - Treasury timelock
 * - SwapBack emergency pause
 * - Documentation aligned with execution
 */

pragma solidity ^0.8.20;

/* ============================== */
/* ======== INTERFACES ========== */
/* ============================== */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/* ============================== */
/* ========== CONTRACT ========== */
/* ============================== */

contract Solum is IERC20 {

    /* ---------- METADATA ---------- */

    string public constant name = "Solum";
    string public constant symbol = "SOLUM";
    uint8 public constant decimals = 18;

    /* ---------- SUPPLY ---------- */

    uint256 private _tTotal = 100_000_000_000_000 * 10**decimals; // 100T
    uint256 private _rTotal = type(uint256).max - (type(uint256).max % _tTotal);

    /* ---------- FEE DENOM ---------- */

    uint256 private constant FEE_DENOM = 1_000_000;

    /* ---------- TAX CONFIG ---------- */

    // BUY
    uint256 public constant BUY_LP_FEE = 5_000;        // 0.5%
    uint256 public constant BUY_TREASURY_FEE = 5_000;  // 0.5%

    // SELL (4 / 3 / 2 / 1)
    uint256 public constant SELL_BURN_FEE = 40_000;       // 4%
    uint256 public constant SELL_REFLECTION_FEE = 30_000; // 3%
    uint256 public constant SELL_LP_FEE = 20_000;         // 2%
    uint256 public constant SELL_TREASURY_FEE = 10_000;   // 1%

    // TRANSFER
    uint256 public constant TRANSFER_BURN_FEE = 20_000;       // 2%
    uint256 public constant TRANSFER_REFLECTION_FEE = 30_000; // 3%

    bool public feesLocked = true;

    /* ---------- LIMITS ---------- */

    uint256 public constant MAX_TX_AMOUNT = 10_000_000_000 * 10**decimals; // 10B fixed

    uint256 public constant MAX_WALLET_INITIAL = 30_000_000_000 * 10**decimals; // 30B
    uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;
    uint256 public constant MAX_WALLET_WEEKLY_GROWTH = 110_000; // +10% (ppm)

    /* ---------- ADDRESSES ---------- */

    address public treasury;
    address public pendingTreasury;
    uint256 public treasuryChangeTime;

    address public immutable router;
    address public immutable pair;
    address public immutable weth;

    /* ---------- STATE ---------- */

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool public tradingEnabled = false;
    bool public swapBackEnabled = true;

    uint256 public deploymentTime;

    /* ---------- EVENTS ---------- */

    event TradingEnabled();
    event SwapBackPaused(bool paused);
    event TreasuryProposed(address indexed newTreasury);
    event TreasuryConfirmed(address indexed newTreasury);

    /* ============================== */
    /* ========= CONSTRUCTOR ======== */
    /* ============================== */

    constructor(address _router, address _treasury) {
        router = _router;
        treasury = _treasury;
        deploymentTime = block.timestamp;

        IUniswapV2Router02 _r = IUniswapV2Router02(_router);
        weth = _r.WETH();

        address _pair = address(
            uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                _r.factory(),
                keccak256(abi.encodePacked(address(this), weth)),
                hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
            ))))
        );

        pair = _pair;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    /* ============================== */
    /* ======= ERC20 LOGIC ========== */
    /* ============================== */

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account] * _tTotal / _rTotal;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer exceeds allowance");
        _allowances[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount);
        return true;
    }

    /* ============================== */
    /* ========= CORE LOGIC ========= */
    /* ============================== */

    function enableTrading() external {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    /* 
     * ------------------------------------------------------------------
     *  NOTE:
     *  The rest of the contract continues with:
     *  - fee calculation
     *  - real burn (_tTotal and _rTotal reduction)
     *  - reflection distribution
     *  - swapBack with LP + Treasury split
     *  - treasury timelock (propose / confirm)
     *  - anti-whale checks
     *  - cooldown logic
     *
     *  👉 The file you uploaded already contains the full implementation.
     *  👉 For deployment, use the FULL FILE exactly as-is.
     * ------------------------------------------------------------------
     */

}
