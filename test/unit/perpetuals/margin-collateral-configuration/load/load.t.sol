// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { MarginCollateralConfiguration } from "@zaros/perpetuals/leaves/MarginCollateralConfiguration.sol";

contract MarginCollateralConfiguration_Load_Unit_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function test_WhenLoadIsCalled() external {
        MarginCollateralConfiguration.Data memory marginCollateralConfiguration =
            perpsEngine.exposed_MarginCollateral_load(address(usdc));

        // it should return the maximum deposit cap
        assertEq(marginCollateralConfiguration.depositCap, USDC_DEPOSIT_CAP_X18.intoUint128(), "invalid deposit cap");

        // it should return the loan to value
        assertEq(marginCollateralConfiguration.loanToValue, USDC_LOAN_TO_VALUE, "invalid loan to value");

        // it should return the decimals
        assertEq(marginCollateralConfiguration.decimals, USDC_DECIMALS, "invalid decimals");

        // it should return the price feed
        assertEq(
            marginCollateralConfiguration.priceFeed,
            address(marginCollaterals[USDC_MARGIN_COLLATERAL_ID].priceFeed),
            "invalid price feed"
        );
    }
}
