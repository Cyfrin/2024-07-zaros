// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { MarginCollateralConfiguration } from "@zaros/perpetuals/leaves/MarginCollateralConfiguration.sol";

// OpenZeppelin Upgradeable dependencies
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";

contract GetMarginCollateralConfiguration_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function test_GivenAValidCollateralAddress() external {
        // it should return the margin collateral configuration
        MarginCollateralConfiguration.Data memory collateralConfiguration =
            perpsEngine.getMarginCollateralConfiguration(address(wstEth));

        assertEq(collateralConfiguration.decimals, ERC20(wstEth).decimals());
    }
}
