// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockDexV2Router
 * @notice Minimal V2-style router mock for Foundry tests.
 * @dev Implements only the functions used by the Solum contract/tests:
 *      - WETH()
 *      - getAmountsOut()
 *      - addLiquidityETH()
 *      - swapExactTokensForETHSupportingFeeOnTransferTokens()
 *
 * This mock is intentionally simple and deterministic:
 * - getAmountsOut returns a 2-hop path output equal to amountIn for each hop.
 * - swapExactTokensForETHSupportingFeeOnTransferTokens does nothing (no ETH minted).
 * - addLiquidityETH returns the input amounts and a dummy liquidity value.
 */
contract MockDexV2Router {
    address private _weth;

    constructor(address weth_) {
        _weth = weth_;
    }

    function WETH() external view returns (address) {
        return _weth;
    }

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        pure
        returns (uint[] memory amounts)
    {
        // Must return a uint[] with length == path.length.
        // For tests, we keep a 1:1 rate (amounts[i] = amountIn).
        uint len = path.length;
        require(len >= 2, "PATH_TOO_SHORT");

        amounts = new uint[](len);
        for (uint i = 0; i < len; i++) {
            amounts[i] = amountIn;
        }
        return amounts;
    }

    function addLiquidityETH(
        address /*token*/,
        uint amountTokenDesired,
        uint /*amountTokenMin*/,
        uint amountETHMin,
        address /*to*/,
        uint /*deadline*/
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        // Accept the ETH sent; return desired token amount and msg.value as ETH added.
        // Respect amountETHMin in the simplest way.
        require(msg.value >= amountETHMin, "ETH_MIN");
        amountToken = amountTokenDesired;
        amountETH = msg.value;
        liquidity = 1; // dummy
        return (amountToken, amountETH, liquidity);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint /*amountIn*/,
        uint /*amountOutMin*/,
        address[] calldata /*path*/,
        address /*to*/,
        uint /*deadline*/
    ) external {
        // Intentionally no-op for tests.
        // Real routers would transfer tokens in and send ETH out.
    }
}
