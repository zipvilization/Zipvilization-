// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Minimal mock of a V2-style DEX router.
 * Only implements the functions required by SolumToken tests.
 */
contract MockDexV2Router {
    address public immutable WETH_ADDRESS;

    constructor(address _weth) {
        WETH_ADDRESS = _weth;
    }

    function WETH() external view returns (address) {
        return WETH_ADDRESS;
    }

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external pure returns (uint[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");

        // FIX: allocate array with correct length
        amounts = new uint[](path.length);

        // Simple 1:1 mock pricing
        amounts[0] = amountIn;
        amounts[1] = amountIn;
    }

    function addLiquidityETH(
        address,
        uint amountTokenDesired,
        uint,
        uint,
        address,
        uint
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        return (amountTokenDesired, msg.value, 1);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint,
        uint,
        address[] calldata,
        address,
        uint
    ) external {
        // no-op (mock)
    }
}
