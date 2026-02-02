// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @notice Minimal V2 router mock for Foundry tests.
 * Purpose:
 * - Provide WETH()
 * - Provide getAmountsOut() so SolumToken can compute a best-effort minOut
 *
 * This mock does NOT perform real swaps or pricing.
 * It returns a 1:1 "price" (amountOut == amountIn) for deterministic tests.
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
        // Minimal sanity: in real routers, path must be >= 2.
        // In tests we just mirror the input across the path length.
        uint256 n = path.length;
        if (n == 0) {
            return new uint;
        }

        amounts = new uint[](n);
        for (uint256 i = 0; i < n; i++) {
            amounts[i] = amountIn;
        }
    }
}
