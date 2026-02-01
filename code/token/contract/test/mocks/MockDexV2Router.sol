// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Minimal V2-style router mock for Foundry tests.
 * Provides:
 * - WETH()
 * - getAmountsOut()
 * - swapExactTokensForETHSupportingFeeOnTransferTokens()
 * - addLiquidityETH()
 *
 * This is NOT a full router implementation. It's just enough for unit tests.
 */
contract MockDexV2Router {
    address public weth;

    constructor(address _weth) {
        weth = _weth;
    }

    function WETH() external view returns (address) {
        return weth;
    }

    function getAmountsOut(uint amountIn, address[] calldata /*path*/)
        external
        pure
        returns (uint[] memory amounts)
    {
        // Return a valid 2-length array (tokenIn -> ETH out).
        amounts = new uint;
        amounts[0] = amountIn;
        amounts[1] = amountIn; // simple 1:1 quote for deterministic tests
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint /*amountIn*/,
        uint /*amountOutMin*/,
        address[] calldata /*path*/,
        address /*to*/,
        uint /*deadline*/
    ) external pure {
        // no-op mock
    }

    function addLiquidityETH(
        address /*token*/,
        uint /*amountTokenDesired*/,
        uint /*amountTokenMin*/,
        uint /*amountETHMin*/,
        address /*to*/,
        uint /*deadline*/
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        // no-op mock; return basic values so calls don't revert
        amountToken = 0;
        amountETH = msg.value;
        liquidity = 0;
    }

    receive() external payable {}
}
