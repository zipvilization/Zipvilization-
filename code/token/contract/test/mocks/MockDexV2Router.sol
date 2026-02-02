// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockDexV2Router {
    address internal _weth;

    constructor(address weth_) {
        _weth = weth_;
    }

    function WETH() external view returns (address) {
        return _weth;
    }

    function getAmountsOut(uint amountIn, address[] calldata)
        external
        pure
        returns (uint[] memory amounts)
    {
        // For tests: pretend 1:1 output
        amounts = new uint;
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
        // minimal stub
        amountToken = amountTokenDesired;
        amountETH = msg.value;
        liquidity = 1;
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint,
        uint,
        address[] calldata,
        address,
        uint
    ) external pure {
        // no-op in tests
    }
}
