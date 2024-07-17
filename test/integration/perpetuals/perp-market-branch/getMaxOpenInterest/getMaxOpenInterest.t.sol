// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";

contract GetMaxOpenInterest_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_GivenTheresAMarketCreated(uint256 marketId) external {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        // it should return the max open interest of the market
        UD60x18 maxOpenInterest = perpsEngine.getMaxOpenInterest(fuzzMarketConfig.marketId);

        assertEq(fuzzMarketConfig.maxOi, maxOpenInterest.intoUint128(), "Invalid max open interest");
    }
}
