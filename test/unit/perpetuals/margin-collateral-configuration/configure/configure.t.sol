// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { MarginCollateralConfiguration } from "@zaros/perpetuals/leaves/MarginCollateralConfiguration.sol";

contract MarginCollateralConfiguration_Configure_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_WhenConfigureIsCalled(
        uint128 newDepositCap,
        uint120 newLoanToValue,
        uint8 newDecimals,
        address newPriceFeed
    )
        external
    {
        perpsEngine.exposed_configure(
            address(usdc), newDepositCap, newLoanToValue, newDecimals, newPriceFeed, MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );

        MarginCollateralConfiguration.Data memory marginCollateralConfiguration =
            perpsEngine.exposed_MarginCollateral_load(address(usdc));

        // it should update the maximum deposit cap
        assertEq(marginCollateralConfiguration.depositCap, newDepositCap, "invalid deposit cap");

        // it should update the loan to value
        assertEq(marginCollateralConfiguration.loanToValue, newLoanToValue, "invalid loan to value");

        // it should update the decimals
        assertEq(marginCollateralConfiguration.decimals, newDecimals, "invalid decimals");

        // it should update the price feed
        assertEq(marginCollateralConfiguration.priceFeed, newPriceFeed, "invalid price feed");
    }
}
