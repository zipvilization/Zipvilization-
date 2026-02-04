// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Solum.sol";
import "./mocks/MockDexV2Router.sol";
import "./mocks/MockPair.sol";

/**
 * @notice Launch-focused tests for Solum (Phase-0 access controls only).
 *
 * We keep SolumToken.t.sol as the stable "core green suite".
 * This file isolates launch mechanics so we can iterate without risking the baseline suite.
 *
 * ASSUMPTIONS (must match canonical Solum.sol in this repo):
 * - Launch window: 48 hours after enableTrading()
 * - Whitelist-only buy window: first 60 minutes after enableTrading()
 * - Buy cooldown: per wallet, 60 minutes, enforced only during the 48h window
 * - Restrictions apply ONLY to buys (from pair). Sells are always allowed.
 *
 * NOTE:
 * In a local VM, we simulate "buy" by transferring from the pair address.
 * We fund the pair with tokens from the owner (fee-exempt) so the pair can send tokens.
 */
contract SolumTokenLaunchTest is Test {
    address internal constant BASE_WETH =
        0x4200000000000000000000000000000000000006;

    address internal owner;
    address internal treasury;

    MockDexV2Router internal router;
    MockPair internal pair;

    Solum internal token;

    address internal wl1;
    address internal publicUser;

    function setUp() public {
        owner = address(this);
        treasury = address(0xBEEF);

        wl1 = address(0xA11CE);
        publicUser = address(0xB0B);

        router = new MockDexV2Router(BASE_WETH);
        pair = new MockPair();

        token = new Solum(address(router), address(pair), treasury);

        // Fund the pair so it can "sell" tokens (simulate buys).
        // Owner is fee-exempt -> this transfer should not take fees.
        token.transfer(address(pair), 1_000 ether);
    }

    /* ------------------------------------------------------------ */
    /* Helpers                                                      */
    /* ------------------------------------------------------------ */

    function _simulateBuy(address buyer, uint256 amount) internal {
        // Buy is defined as: from == pair
        vm.prank(address(pair));
        token.transfer(buyer, amount);
    }

    function _simulateSell(address seller, uint256 amount) internal {
        // Sell is defined as: to == pair
        vm.prank(seller);
        token.transfer(address(pair), amount);
    }

    /* ------------------------------------------------------------ */
    /* Tests                                                        */
    /* ------------------------------------------------------------ */

    function testLaunchWhitelistOnlyDuringFirstHour() public {
        token.enableTrading();

        // During first hour: non-whitelisted BUY must revert.
        vm.expectRevert(); // we intentionally don't overfit revert string; canonical may differ
        _simulateBuy(publicUser, 1 ether);

        // If the contract exposes whitelist admin functions, whitelist wl1 and allow buy.
        // IMPORTANT: This call MUST match the real function name in Solum.sol.
        // If your canonical contract uses a different name, we update here to match exactly.
        token.setWhitelist(wl1, true);

        _simulateBuy(wl1, 1 ether);
        assertTrue(token.balanceOf(wl1) > 0);
    }

    function testPublicBuysAllowedAfterFirstHour() public {
        token.enableTrading();

        // Whitelist wl1 for completeness (depends on your canonical logic)
        token.setWhitelist(wl1, true);

        // Move time forward by 61 minutes: public phase
        vm.warp(block.timestamp + 61 minutes);

        _simulateBuy(publicUser, 1 ether);
        assertTrue(token.balanceOf(publicUser) > 0);
    }

    function testBuyCooldownEnforcedDuring48hWindow() public {
        token.enableTrading();

        // Move to public phase (avoid whitelist gating)
        vm.warp(block.timestamp + 61 minutes);

        // First buy works
        _simulateBuy(publicUser, 1 ether);

        // Immediate second buy must revert due to 60m cooldown
        vm.expectRevert();
        _simulateBuy(publicUser, 1 ether);

        // After 60 minutes, buy allowed again
        vm.warp(block.timestamp + 60 minutes);
        _simulateBuy(publicUser, 1 ether);
    }

    function testCooldownDoesNotBlockSells() public {
        token.enableTrading();

        // Move to public phase
        vm.warp(block.timestamp + 61 minutes);

        // Buy once (starts cooldown)
        _simulateBuy(publicUser, 5 ether);

        // Sell should still be allowed even during cooldown
        _simulateSell(publicUser, 1 ether);
        assertTrue(token.balanceOf(publicUser) > 0);
    }

    function testLaunchRulesExpireAfter48Hours() public {
        token.enableTrading();

        // Move time to after 48h window (+48h + a little buffer)
        vm.warp(block.timestamp + 48 hours + 1 minutes);

        // Buy twice back-to-back should be allowed once launch window is over
        _simulateBuy(publicUser, 1 ether);
        _simulateBuy(publicUser, 1 ether);
        assertTrue(token.balanceOf(publicUser) > 0);
    }
}
