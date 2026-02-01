// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

// Adjust the import path if your repo structure differs.
// With your current layout, this should be correct:
import "../SolumToken.sol";
import "./mocks/MockDexV2Router.sol";

/**
 * @dev Minimal "build-green" tests for SolumToken.
 * These tests are intentionally scoped to:
 * - compile validation
 * - deployment invariants
 * - trading gate behavior
 *
 * When full tax/burn/reflection/swapback is reintroduced, extend the suite.
 */
contract SolumTokenTest is Test {
    // Canonical Base WETH (valid EVM address; used only as an address in tests)
    address internal constant BASE_WETH = 0x4200000000000000000000000000000000000006;

    address internal owner = address(this);
    address internal treasury = address(0xBEEF);
    address internal alice = address(0xA11CE);
    address internal bob   = address(0xB0B);

    SolumToken internal token;
    MockDexV2Router internal router;

    // Dummy pair address for tests (not a real pool)
    address internal pair = address(0xCAFE);

    function setUp() public {
        router = new MockDexV2Router(BASE_WETH);

        token = new SolumToken(
            address(router),
            pair,
            BASE_WETH,
            treasury
        );
    }

    function testInitialSupplyMintedToOwner() public {
        // total supply should be 100T (as per contract)
        uint256 total = token.totalSupply();
        assertEq(total, 100_000_000_000_000 * 1e18);

        // deployer receives full initial supply
        assertEq(token.balanceOf(owner), total);
    }

    function testPreTradingTransfersAreBlockedForNonExempt() public {
        // Owner is fee-exempt by constructor.
        // Transfer from owner -> alice should succeed even before trading enabled.
        token.transfer(alice, 1e18);
        assertEq(token.balanceOf(alice), 1e18);

        // Now alice is NOT fee-exempt. Transfers from alice should revert before trading enabled.
        vm.prank(alice);
        vm.expectRevert(bytes("TRADING_OFF"));
        token.transfer(bob, 1);
    }

    function testEnableTradingOwnerOnly() public {
        // alice cannot enable
        vm.prank(alice);
        vm.expectRevert(bytes("OWNER_ONLY"));
        token.enableTrading();

        // owner can enable
        token.enableTrading();
    }

    function testTransfersWorkAfterTradingEnabled() public {
        // owner -> alice (pre-trading allowed because owner is exempt)
        token.transfer(alice, 10e18);

        // enable trading
        token.enableTrading();

        // alice -> bob should now work
        vm.prank(alice);
        token.transfer(bob, 3e18);

        assertEq(token.balanceOf(bob), 3e18);
        assertEq(token.balanceOf(alice), 7e18);
    }
}
