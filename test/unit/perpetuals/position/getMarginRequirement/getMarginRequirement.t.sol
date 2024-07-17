// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

contract Position_GetMarginRequirement_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_WhenGetMarginRequirementIsCalled(uint256 marketId, uint256 notionalValue) external {
        changePrank({ msgSender: users.naruto.account });

        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        UD60x18 notionalValueX18 = ud60x18(notionalValue);
        UD60x18 initialMarginX18 = ud60x18(fuzzMarketConfig.imr);
        UD60x18 maintenanceMarginX18 = ud60x18(fuzzMarketConfig.mmr);

        UD60x18 expectedInitialMarginUsdX18 = notionalValueX18.mul(initialMarginX18);
        UD60x18 expectedMaintenanceMarginUsdX18 = notionalValueX18.mul(maintenanceMarginX18);

        (UD60x18 initialMarginUsdX18, UD60x18 maintenanceMarginUsdX18) =
            perpsEngine.exposed_getMarginRequirements(notionalValueX18, initialMarginX18, maintenanceMarginX18);

        // it should return the initial margin usd
        assertEq(
            expectedInitialMarginUsdX18.intoUint256(),
            initialMarginUsdX18.intoUint256(),
            "initial margin usd is incorrect"
        );

        // it should return the maintenance margin rate usd
        assertEq(
            expectedMaintenanceMarginUsdX18.intoUint256(),
            maintenanceMarginUsdX18.intoUint256(),
            "maintenance usd is incorrect"
        );
    }
}
