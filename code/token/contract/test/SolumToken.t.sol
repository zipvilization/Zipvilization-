// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Solum.sol";

contract SolumTokenTest is Test {
    Solum internal solum;

    address internal owner;
    address internal treasury;
    address internal router;
    address internal pair;

    // Canonical WETH on Base
    address internal constant BASE_WETH =
        0x4200000000000000000000000000000000000006;

    function setUp() public {
        owner = address(this);
        treasury = address(0xBEEF);
        router = address(0xCAFE);
        pair = address(0xFACE);

        solum = new Solum(
            router,
            pair,
            BASE_WETH,
            treasury
        );
    }

    /* ---------------------------------------------------------- */
    /*                      BASIC PROPERTIES                      */
    /* ---------------------------------------------------------- */

    function testMetadata() public {
        assertEq(solum.name(), "Solum");
        assertEq(solum.symbol(), "SOLUM");
        assertEq(solum.decimals(), 18);
    }

    function testTotalSupplyAssignedToOwner() public {
        uint256 total = solum.totalSupply();
        assertEq(solum.balanceOf(owner), total);
    }

    /* ---------------------------------------------------------- */
    /*                      TRADING CONTROL                       */
    /* ---------------------------------------------------------- */

    function testTradingDisabledByDefault() public {
        assertFalse(solum.tradingEnabled());
    }

    function testEnableTrading() public {
        solum.enableTrading();
        assertTrue(solum.tradingEnabled());
    }

    function testNonExemptCannotTransferBeforeTrading() public {
        address user = address(0x1234);

        vm.expectRevert("TRADING_OFF");
        vm.prank(owner);
        solum.transfer(user, 1 ether);
    }

    /* ---------------------------------------------------------- */
    /*                        TRANSFERS                           */
    /* ---------------------------------------------------------- */

    function testTransferAfterTradingEnabled() public {
        address user = address(0x1234);

        solum.enableTrading();
        solum.transfer(user, 1 ether);

        assertEq(solum.balanceOf(user), 1 ether);
    }

    /* ---------------------------------------------------------- */
    /*                      TREASURY SETUP                        */
    /* ---------------------------------------------------------- */

    function testTreasuryIsFeeExempt() public {
        assertTrue(solum.isFeeExempt(treasury));
    }

    function testTreasuryIsLimitExempt() public {
        assertTrue(solum.isLimitExempt(treasury));
    }

    /* ---------------------------------------------------------- */
    /*                      SANITY CHECKS                         */
    /* ---------------------------------------------------------- */

    function testRouterAndPairExemptions() public {
        assertTrue(solum.isLimitExempt(router));
        assertTrue(solum.isLimitExempt(pair));
    }
}
