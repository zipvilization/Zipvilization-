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
 * Key rule for test stability:
 * - NEVER use absolute timestamps in vm.warp(x) unless x is monotonic and understood.
 * - Prefer vm.warp(block.timestamp + delta) to avoid time going backwards.
 *
 * We test the canonical launch protections added to Solum:
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
    // Canonical WETH on Base (valid EVM address; it doesn't need to exist on local VM)
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

        // Solum constructor in this repo: (router, pair, treasury)
        token = new Solum(address(router), address(pair), treasury);

        // Enable trading to start launch window and timestamp.
        token.enableTrading();

        // Fund pair so it can simulate buys (pair -> user).
        // Owner is fee-exempt and pair is limit-exempt by default, so this is clean.
        token.transfer(address(pair), 1_000 ether);
    }

    function testWhitelistOnlyBuysDuringFirstHour() public {
        // During whitelist window, non-whitelisted buys must revert.
        vm.prank(address(pair));
        vm.expectRevert("WHITELIST_ONLY");
        token.transfer(bob, 10 ether);

        // Whitelist alice, then buy should succeed.
        token.setWhitelist(alice, true);

        vm.prank(address(pair));
        token.transfer(alice, 10 ether);

        assertTrue(token.balanceOf(alice) > 0, "ALICE_DID_NOT_RECEIVE");
    }

    function testBuyCooldownAppliesDuringFirst48h() public {
        token.setWhitelist(alice, true);

        // First buy succeeds.
        vm.prank(address(pair));
        token.transfer(alice, 10 ether);

        // Second buy immediately must revert due to cooldown (BUYS only).
        vm.prank(address(pair));
        vm.expectRevert("BUY_COOLDOWN");
        token.transfer(alice, 1 ether);

        // After 60 minutes, buy should succeed again.
        vm.warp(block.timestamp + 60 minutes);

        vm.prank(address(pair));
        token.transfer(alice, 1 ether);

        assertTrue(token.balanceOf(alice) > 10 ether, "ALICE_BALANCE_NOT_INCREASED");
    }

    function testPublicBuysAllowedAfterFirstHourButCooldownStillActiveUntil48h() public {
        // Move time forward past whitelist window (60 min) but still inside 48h.
        vm.warp(block.timestamp + 60 minutes + 1);

        // bob is NOT whitelisted, but should be allowed to buy now (public phase).
        vm.prank(address(pair));
        token.transfer(bob, 10 ether);

        // Immediate second buy should hit cooldown.
        vm.prank(address(pair));
        vm.expectRevert("BUY_COOLDOWN");
        token.transfer(bob, 1 ether);

        // After cooldown, second buy should pass.
        vm.warp(block.timestamp + 60 minutes);

        vm.prank(address(pair));
        token.transfer(bob, 1 ether);

        assertTrue(token.balanceOf(bob) > 10 ether, "BOB_BALANCE_NOT_INCREASED");
    }

    function testLaunchRulesExpireAfter48h() public {
        // Move time forward beyond 48 hours (launch buy rules duration).
        vm.warp(block.timestamp + 48 hours + 1);

        // Not whitelisted: should still be allowed to buy.
        vm.prank(address(pair));
        token.transfer(bob, 10 ether);

        // Cooldown should be inactive after 48h, so immediate second buy should NOT revert.
        vm.prank(address(pair));
        token.transfer(bob, 1 ether);

        assertTrue(token.balanceOf(bob) > 10 ether, "BOB_BALANCE_NOT_INCREASED");
    }

    function testSellsAreNeverBlockedByLaunchRules() public {
        // Stay inside whitelist window (default right after enableTrading()).
        token.setWhitelist(alice, true);

        // Buy for alice (pair -> alice).
        vm.prank(address(pair));
        token.transfer(alice, 10 ether);

        // Sell for alice (alice -> pair) must NOT be blocked by whitelist/cooldown rules.
        // Note: This will apply sell fees (alice is not fee-exempt), which is fine.
        vm.prank(alice);
        token.transfer(address(pair), 1 ether);

        // If we got here without revert, sells are not restricted by launch rules.
        assertTrue(true);
    }
}
