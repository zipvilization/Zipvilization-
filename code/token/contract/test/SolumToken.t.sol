// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Solum.sol";
import "./mocks/MockDexV2Router.sol";
import "./mocks/MockPair.sol";

/**
 * @notice Minimal but meaningful tests for the CANONICAL SolumToken contract.
 * Focus:
 * - supply assigned to deployer
 * - pre-trading gate (non-exempt -> non-exempt blocked)
 * - enableTrading is owner-only
 * - transfer fees apply on wallet->wallet transfers (5% total; receiver gets ~95%)
 * - real burn on transfer reduces total supply by ~2% of transfer amount (transferFee split 2/3 burn/reflection)
 *
 * We avoid triggering swapBack in tests (no sells to pair), keeping mocks minimal.
 */
contract SolumTokenTest is Test {
    // Canonical WETH on Base (valid EVM address; it doesn't need to exist on local VM)
    address internal constant BASE_WETH =
        0x4200000000000000000000000000000000000006;

    address internal owner;
    address internal treasury;

    MockDexV2Router internal router;
    MockPair internal pair;

    SolumToken internal token;

    address internal alice;
    address internal bob;

    function setUp() public {
        owner = address(this);
        treasury = address(0xBEEF);

        alice = address(0xA11CE);
        bob = address(0xB0B);

        router = new MockDexV2Router(BASE_WETH);
        pair = new MockPair();

        // NOTE: constructor is (router, pair, treasury)
        token = new SolumToken(address(router), address(pair), treasury);
    }

    function testInitialSupplyMintedToOwner() public {
        assertEq(token.balanceOf(owner), token.totalSupply(), "OWNER_NOT_FULL_SUPPLY");
    }

    function testEnableTradingOwnerOnly() public {
        vm.prank(alice);
        vm.expectRevert("OWNER_ONLY");
        token.enableTrading();

        token.enableTrading();
        assertTrue(token.tradingEnabled(), "TRADING_NOT_ENABLED");
    }

    function testPreTradingGateBlocksNonExemptTransfers() public {
        // Owner is fee-exempt by default -> owner -> alice is allowed pre-trading
        token.transfer(alice, 1 ether);

        // alice -> bob is non-exempt -> non-exempt, must revert pre-trading
        vm.prank(alice);
        vm.expectRevert("TRADING_OFF");
        token.transfer(bob, 0.1 ether);
    }

    function testTransferFeeAndBurnAfterTradingEnabled() public {
        token.enableTrading();

        // Fund alice from exempt owner (no fee on this transfer)
        token.transfer(alice, 100 ether);

        uint256 supplyBefore = token.totalSupply();

        uint256 sendAmount = 10 ether;

        uint256 bobBefore = token.balanceOf(bob);

        vm.prank(alice);
        token.transfer(bob, sendAmount);

        uint256 bobAfter = token.balanceOf(bob);

        // Transfer fee total initial is 5% => receiver should get ~95%
        uint256 expectedReceived = (sendAmount * 95) / 100;

        // Allow small tolerance due to reflection rate integer division.
        uint256 received = bobAfter - bobBefore;
        assertTrue(
            received == expectedReceived ||
            received + 1 == expectedReceived ||
            received == expectedReceived + 1,
            "RECEIVE_MISMATCH"
        );

        // Transfer fee split: 2/3 burn over 5% total => burn is 2% of amount
        uint256 expectedBurn = (sendAmount * 2) / 100;
        uint256 supplyAfter = token.totalSupply();

        assertEq(supplyBefore - supplyAfter, expectedBurn, "BURN_SUPPLY_MISMATCH");
    }
}
