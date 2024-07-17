// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { Base_Test } from "test/Base.t.sol";
import { MockPriceFeed } from "test/mocks/MockPriceFeed.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { sd59x18 } from "@prb-math/SD59x18.sol";

contract GetMarginRequirementForTrade_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();

        createPerpMarkets();

        changePrank({ msgSender: users.naruto.account });
    }

    function test_GivenTheresAMarketCreated(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        initialMarginRate = bound({ x: initialMarginRate, min: fuzzMarketConfig.imr, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        UD60x18 markPriceX18 =
            perpsEngine.getMarkPrice(fuzzMarketConfig.marketId, fuzzMarketConfig.mockUsdPrice, sizeDelta);

        UD60x18 orderValueX18 = markPriceX18.mul(sd59x18(sizeDelta).abs().intoUD60x18());

        UD60x18 expectedInitialMarginUsd = orderValueX18.mul(ud60x18(fuzzMarketConfig.imr));
        UD60x18 expectedMaintenanceMarginUsd = orderValueX18.mul(ud60x18(fuzzMarketConfig.mmr));
        UD60x18 expectedOrderFeeUsd =
            perpsEngine.exposed_getOrderFeeUsd(fuzzMarketConfig.marketId, sd59x18(sizeDelta), markPriceX18);
        SettlementConfiguration.Data memory settlementConfiguration = perpsEngine.exposed_SettlementConfiguration_load(
            fuzzMarketConfig.marketId, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID
        );
        UD60x18 expectedSettlementFeeUsd = ud60x18(uint256(settlementConfiguration.fee));

        (
            UD60x18 initialMarginUsdX18,
            UD60x18 maintenanceMarginUsdX18,
            UD60x18 orderFeeUsdX18,
            UD60x18 settlementFeeUsdX18
        ) = perpsEngine.getMarginRequirementForTrade(
            fuzzMarketConfig.marketId, sizeDelta, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID
        );

        // it should return the initial margin usd
        assertEq(
            initialMarginUsdX18.intoUint256(),
            expectedInitialMarginUsd.intoUint256(),
            "initial margin usd is not correct"
        );

        // it should return the maintenance margin usd
        assertEq(
            maintenanceMarginUsdX18.intoUint256(),
            expectedMaintenanceMarginUsd.intoUint256(),
            "maintenance margin usd is not correct"
        );

        // it should return the order fee usd
        assertEq(orderFeeUsdX18.intoUint256(), expectedOrderFeeUsd.intoUint256(), "order fee usd is not correct");

        // it should return the settlement fee usd
        assertEq(
            settlementFeeUsdX18.intoUint256(),
            expectedSettlementFeeUsd.intoUint256(),
            "settlement fee usd is not correct"
        );
    }
}
