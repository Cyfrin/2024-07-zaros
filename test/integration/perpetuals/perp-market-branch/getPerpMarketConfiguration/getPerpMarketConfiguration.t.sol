// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";
import { Base_Test } from "test/Base.t.sol";

contract GetPerpMarketConfiguration_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_GivenTheresAMarketCreated(uint256 marketId) external {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        (
            string memory name,
            string memory symbol,
            uint128 initialMarginRateX18,
            uint128 maintenanceMarginRateX18,
            uint128 maxOpenInterest,
            uint128 maxSkew,
            uint128 minTradeSizeX18,
            uint256 skewScale,
            OrderFees.Data memory orderFees
        ) = perpsEngine.getPerpMarketConfiguration(fuzzMarketConfig.marketId);

        // it should return name
        assertEq(name, fuzzMarketConfig.marketName, "Invalid market name");

        // it should return symbol
        assertEq(symbol, fuzzMarketConfig.marketSymbol, "Invalid market symbol");

        // it should return initial margin rate
        assertEq(initialMarginRateX18, fuzzMarketConfig.imr, "Invalid initial margin rate");

        // it should return maintenance margin rate
        assertEq(maintenanceMarginRateX18, fuzzMarketConfig.mmr, "Invalid maintenance margin rate");

        // it should return max open interest
        assertEq(maxOpenInterest, fuzzMarketConfig.maxOi, "Invalid max open interest");

        // it should return skew scale
        assertEq(maxSkew, fuzzMarketConfig.maxSkew, "Invalid max skew");

        // it should return skew scale
        assertEq(skewScale, fuzzMarketConfig.skewScale, "Invalid skew scale");

        // it should return min trade size
        assertEq(minTradeSizeX18, fuzzMarketConfig.minTradeSize, "Invalid min trade size");

        // it should return order fees
        assertEq(orderFees.makerFee, fuzzMarketConfig.orderFees.makerFee, "Invalid orderFees.makerFee");
        assertEq(orderFees.takerFee, fuzzMarketConfig.orderFees.takerFee, "Invalid orderFees.takerFee");
    }
}
