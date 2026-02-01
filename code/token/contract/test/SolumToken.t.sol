// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../SolumToken.sol";

contract SolumTokenTest is Test {
    Solum solum;

    // Base canonical WETH (Base mainnet & Base Sepolia)
    address internal constant WETH =
        0x4200000000000000000000000000000000000006;

    address internal constant ROUTER =
        address(0x1111111111111111111111111111111111111111);

    address internal constant PAIR =
        address(0x2222222222222222222222222222222222222222);

    address internal constant TREASURY =
        address(0x3333333333333333333333333333333333333333);

    function setUp() public {
        solum = new Solum(
            ROUTER,
            PAIR,
            WETH,
            TREASURY
        );
    }

    function testInitialSupplyAssignedToDeployer() public {
        uint256 totalSupply = solum.totalSupply();
        uint256 deployerBalance = solum.balanceOf(address(this));

        assertEq(deployerBalance, totalSupply, "Supply not assigned to deployer");
    }

    function testTradingDisabledByDefault() public {
        vm.expectRevert("TRADING_OFF");
        solum.transfer(address(0xdead), 1 ether);
    }

    function testEnableTrading() public {
        solum.enableTrading();
        solum.transfer(address(0xdead), 1 ether);

        assertEq(
            solum.balanceOf(address(0xdead)),
            1 ether,
            "Transfer failed after trading enabled"
        );
    }
}
