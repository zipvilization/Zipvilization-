// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * ISolum
 * Interface-only mirror of the canonical Solum contract.
 *
 * IMPORTANT:
 * - This is NOT an implementation.
 * - Canonical implementation: code/token/contract/src/Solum.sol
 *
 * Keep this interface minimal and stable.
 * Add functions/events only when they exist in the canonical contract.
 */
interface ISolum {
    // --- ERC20 ---
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // --- Canonical public signals (if present) ---
    function tradingEnabled() external view returns (bool);
    function swapBackEnabled() external view returns (bool);

    function treasury() external view returns (address);
    function router() external view returns (address);
    function pair() external view returns (address);
    function weth() external view returns (address);

    // --- Events (ERC20) ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // --- Canonical events (if present) ---
    event TradingEnabled();
    event SwapBackPaused(bool paused);
    event TreasuryProposed(address indexed newTreasury, uint256 availableAt);
    event TreasuryConfirmed(address indexed newTreasury);
    event SwapBackConfigUpdated(uint256 threshold, uint256 maxAmount, uint256 cooldown, uint256 slippageBps);
    }
