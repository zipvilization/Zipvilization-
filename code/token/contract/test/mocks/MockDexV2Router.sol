// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @dev Deterministic V2-style router mock for testing.
 * NOT a real DEX implementation.
 */
contract MockDexV2Router {
    address public immutable WETH;

    // ETH-per-token rate (scaled by 1e18)
    uint256 public rate;

    constructor(address weth_, uint256 rate_) {
        WETH = weth_;
        rate = rate_;
    }

    receive() external payable {}

    function setRate(uint256 newRate) external {
        rate = newRate;
    }

    function getAmountsOut(uint amountIn, address[] calldata)
        external
        view
        returns (uint[] memory amounts)
    {
        amounts = new uint;
        amounts[0] = amountIn;
        amounts[1] = (amountIn * rate) / 1e18;
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata,
        address to,
        uint
    ) external {
        IERC20Minimal(msg.sender).transferFrom(msg.sender, address(this), amountIn);

        uint256 out = (amountIn * rate) / 1e18;
        require(out >= amountOutMin, "MIN_OUT");

        (bool ok, ) = to.call{value: out}("");
        require(ok, "ETH_SEND_FAIL");
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint,
        uint,
        address,
        uint
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        IERC20Minimal(token).transferFrom(msg.sender, address(this), amountTokenDesired);

        amountToken = amountTokenDesired;
        amountETH = msg.value;
        liquidity = amountTokenDesired / 1e6 + msg.value / 1e12 + 1;
    }
}
