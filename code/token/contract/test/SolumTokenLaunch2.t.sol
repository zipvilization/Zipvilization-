// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Solum.sol";
import "./mocks/MockDexV2Router.sol";
import "./mocks/MockPair.sol";

/**
 * @notice Launch Rules test suite (Phase-0 only) — SECONDARY SUITE.
 *
 * This suite exists to validate the same launch rules with an independent test contract.
 * We intentionally make warps deterministic:
 * - store timestamps at critical actions (e.g., first buy)
 * - warp to (storedTime + delta) to avoid any accidental reuse of absolute time
 *
 * Rules tested:
 * - First 60 minutes after enableTrading(): ONLY whitelisted wallets can BUY (from pair).
 * - First 48 hours after enableTrading(): per-wallet buy cooldown applies (BUYS only).
 * - After 48 hours: launch buy rules are inactive (no whitelist gate, no cooldown gate).
 * - Sells are never restricted by launch rules.
 *
 * IMPORTANT:
 * A "BUY" is detected as `from == pair`.
 * To simulate buys, we fund `pair` with tokens and then prank transfers from `pair` to users.
 */
contract SolumTokenLaunch2Test is Test {
    address internal constant BASE_WETH =
        0x4200000000000000000000000000000000000006;

    address internal owner;
    address internal treasury;

    MockDexV2Router internal router;
    MockPair internal pair;

    Solum internal token;

    address internal alice; // whitelisted (in some tests)
    address internal bob;   // not whitelisted

    function setUp() public {
        owner = address(this);
        treasury = address(0xBEEF);

        alice = address(0xA11CE);
        bob = address(0xB0B);

        router = new MockDexV2Router(BASE_WETH);
        pair = new MockPair();

        token = new Solum(address(router), address(pair), treasury);

        // Start launch window.
        token.enableTrading();

        // Fund pair so it can simulate buys (pair -> user).
        token.transfer(address(pair), 1_000 ether);
    }

    function testWhitelistOnlyBuysDuringFirstHour() public {
        vm.prank(address(pair));
        vm.expectRevert("WHITELIST_ONLY");
        token.transfer(bob, 10 ether);

        token.setWhitelist(alice, true);

        vm.prank(address(pair));
        token.transfer(alice, 10 ether);

        assertTrue(token.balanceOf(alice) > 0, "ALICE_DID_NOT_RECEIVE");
    }

    function testBuyCooldownAppliesDuringFirst48h() public {
        token.setWhitelist(alice, true);

        vm.prank(address(pair));
        token.transfer(alice, 10 ether);

        vm.prank(address(pair));
        vm.expectRevert("BUY_COOLDOWN");
        token.transfer(alice, 1 ether);

        // Warp strictly past cooldown boundary (deterministic +1s).
        uint256 firstBuyTime = block.timestamp;
        vm.warp(firstBuyTime + 60 minutes + 1);

        vm.prank(address(pair));
        token.transfer(alice, 1 ether);

        assertTrue(token.balanceOf(alice) > 10 ether, "ALICE_BALANCE_NOT_INCREASED");
    }

    function testPublicBuysAllowedAfterFirstHourButCooldownStillActiveUntil48h() public {
        // Move time forward past whitelist window (60 min) but still inside 48h.
        uint256 tStart = block.timestamp;
        vm.warp(tStart + 60 minutes + 1);

        // bob is NOT whitelisted, but should be allowed to buy now (public phase).
        vm.prank(address(pair));
        token.transfer(bob, 10 ether);

        // Capture exact time of the first buy (cooldown anchor).
        uint256 firstBuyTime = block.timestamp;

        // Immediate second buy should hit cooldown.
        vm.prank(address(pair));
        vm.expectRevert("BUY_COOLDOWN");
        token.transfer(bob, 1 ether);

        // Warp strictly past cooldown boundary (deterministic +1s).
        vm.warp(firstBuyTime + 60 minutes + 1);

        vm.prank(address(pair));
        token.transfer(bob, 1 ether);

        assertTrue(token.balanceOf(bob) > 10 ether, "BOB_BALANCE_NOT_INCREASED");
    }

    function testLaunchRulesExpireAfter48h() public {
        vm.warp(block.timestamp + 48 hours + 1);

        vm.prank(address(pair));
        token.transfer(bob, 10 ether);

        // Cooldown should be inactive after 48h, so immediate second buy should NOT revert.
        vm.prank(address(pair));
        token.transfer(bob, 1 ether);

        assertTrue(token.balanceOf(bob) > 10 ether, "BOB_BALANCE_NOT_INCREASED");
    }

    function testSellsAreNeverBlockedByLaunchRules() public {
        token.setWhitelist(alice, true);

        vm.prank(address(pair));
        token.transfer(alice, 10 ether);

        vm.prank(alice);
        token.transfer(address(pair), 1 ether);

        assertTrue(true);
    }
}
