// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

// Adjust this import if your filename differs.
import "../SolumToken.sol";

import "./mocks/MockDexV2Router.sol";
import "./mocks/MockPair.sol";

/**
 * SolumToken tests:
 * - Real burn on sells reduces totalSupply
 * - Reflection increases passive holder balance
 * - swapBack triggers and pays treasury
 * - freezeConfig (Option A) blocks future config edits
 */
contract SolumTokenTest is Test {
    // actors
    address internal owner = address(0xA11CE);
    address internal treasury = address(0xBEEF);
    address internal user1 = address(0x1111);
    address internal user2 = address(0x2222);

    // mock infra
    address internal weth = address(0xWETH); // dummy WETH address
    MockPair internal pair;
    MockDexV2Router internal router;

    // token under test
    Solum internal token;

    function setUp() public {
        vm.startPrank(owner);

        pair = new MockPair();

        // rate: 1 token -> ~1e-6 ETH (scaled by 1e18)
        router = new MockDexV2Router(weth, 1e12);

        // fund router with ETH so swaps can pay out
        vm.deal(address(router), 100 ether);

        token = new Solum(address(router), address(pair), weth, treasury);

        // enable trading for tests
        token.enableTrading();

        vm.stopPrank();

        // distribute initial balances
        vm.startPrank(owner);
        token.transfer(user1, 5_000_000_000 * 1e18); // 5B
        token.transfer(user2, 5_000_000_000 * 1e18); // 5B
        vm.stopPrank();
    }

    function testFreezeBlocksConfigAndExemptions() public {
        vm.startPrank(owner);

        // Pre-freeze changes allowed
        token.setSwapBackConfig(1e18, 2e18, 0, 300);
        token.setFeeExempt(user1, true);
        token.setLimitExempt(user1, true);

        // Freeze configuration
        token.freezeConfig();

        // Post-freeze changes must revert
        vm.expectRevert("CONFIG_FROZEN");
        token.setSwapBackConfig(2e18, 3e18, 0, 300);

        vm.expectRevert("CONFIG_FROZEN");
        token.setFeeExempt(user2, true);

        vm.expectRevert("CONFIG_FROZEN");
        token.setLimitExempt(user2, true);

        vm.stopPrank();
    }

    function testSellBurnReducesTotalSupply() public {
        // avoid swapBack noise
        vm.prank(owner);
        token.setSwapBackPaused(true);

        uint256 supplyBefore = token.totalSupply();

        uint256 sellAmount = 1_000_000 * 1e18; // 1M
        uint256 expectedBurn =
            (sellAmount * token.SELL_BURN_FEE()) / 1_000_000;

        vm.prank(user1);
        token.transfer(address(pair), sellAmount);

        uint256 supplyAfter = token.totalSupply();
        assertEq(supplyBefore - supplyAfter, expectedBurn, "burn mismatch");
    }

    function testReflectionRewardsPassiveHolder() public {
        vm.prank(owner);
        token.setSwapBackPaused(true);

        uint256 beforeBal = token.balanceOf(user2);

        uint256 sellAmount = 2_000_000 * 1e18; // 2M
        vm.prank(user1);
        token.transfer(address(pair), sellAmount);

        uint256 afterBal = token.balanceOf(user2);
        assertGt(afterBal, beforeBal, "no reflection gain");
    }

    function testSwapBackPaysTreasury() public {
        vm.startPrank(owner);

        // make swapBack easy to trigger
        token.setSwapBackConfig(
            100 * 1e18,            // threshold
            10_000_000 * 1e18,     // maxAmount
            0,                     // cooldown
            300                    // slippage
        );

        vm.stopPrank();

        vm.deal(treasury, 0);

        // First sell builds contract balance
        vm.prank(user1);
        token.transfer(address(pair), 1_000_000 * 1e18);

        uint256 treasuryBefore = treasury.balance;

        // Second sell triggers swapBack
        vm.prank(user1);
        token.transfer(address(pair), 1_000_000 * 1e18);

        uint256 treasuryAfter = treasury.balance;
        assertGt(treasuryAfter, treasuryBefore, "treasury not paid");
    }
}
