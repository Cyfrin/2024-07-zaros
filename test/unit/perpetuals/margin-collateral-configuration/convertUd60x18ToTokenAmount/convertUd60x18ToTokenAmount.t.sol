// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { Base_Test } from "test/Base.t.sol";
import { MarginCollateralConfiguration } from "@zaros/perpetuals/leaves/MarginCollateralConfiguration.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

contract MarginCollateralConfiguration_ConvertUd60x18ToTokenAmount_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_WhenMarginCollateralDecimalsIsEqualToSystemDecimals(uint256 expectedValue) external {
        uint256 value = perpsEngine.exposed_convertUd60x18ToTokenAmount(address(wstEth), ud60x18(expectedValue));

        // it should return the amount to uint256
        assertEq(value, expectedValue, "value is not correct");
    }

    function testFuzz_WhenMarginCollateralDecimalsIsNotEqualToSystemDecimals(
        uint128 newDepositCap,
        uint120 newLoanToValue,
        uint8 newDecimals,
        address newPriceFeed
    )
        external
    {
        uint256 amount = 100;

        vm.assume(newDecimals < Constants.SYSTEM_DECIMALS && newDecimals > 0);

        perpsEngine.exposed_configure(
            address(usdc), newDepositCap, newLoanToValue, newDecimals, newPriceFeed, MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );

        uint256 expectedValue = ((amount) / 10 ** (Constants.SYSTEM_DECIMALS - newDecimals));

        uint256 value = perpsEngine.exposed_convertUd60x18ToTokenAmount(address(usdc), ud60x18(amount));

        // it should return the amount raised to the decimals of the system minus the decimals of the margin
        // collateral to uint256
        assertEq(value, expectedValue, "value is not correct");
    }
}
