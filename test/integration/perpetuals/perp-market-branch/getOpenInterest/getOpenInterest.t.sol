// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { OrderBranch } from "@zaros/perpetuals/branches/OrderBranch.sol";
import { Base_Test } from "test/Base.t.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, unary } from "@prb-math/SD59x18.sol";

contract GetOpenInterest_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function test_GivenTheresAPositionCreated(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId,
        uint256 priceShift
    )
        external
    {
        changePrank({ msgSender: users.naruto.account });

        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        priceShift = bound({ x: priceShift, min: 1.1e18, max: 10e18 });

        initialMarginRate =
            bound({ x: initialMarginRate, min: fuzzMarketConfig.marginRequirements, max: MAX_MARGIN_REQUIREMENTS });

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

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);

        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        changePrank({ msgSender: marketOrderKeeper });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);

        (UD60x18 longsOpenInterest, UD60x18 shortsOpenInterest, UD60x18 totalOpenInterest) =
            perpsEngine.getOpenInterest(fuzzMarketConfig.marketId);

        uint256 expectedOpenInterest = sd59x18(sizeDelta).abs().intoUD60x18().intoUint256();

        // it should return longs open interest
        if (isLong) {
            assertAlmostEq(
                expectedOpenInterest, longsOpenInterest.intoUint256(), 1, "longs open interest is not correct"
            );
        }

        // it should return shorts open interest
        if (!isLong) {
            assertAlmostEq(
                expectedOpenInterest, shortsOpenInterest.intoUint256(), 1, "shorts open interest is not correct"
            );
        }

        // it should return total open interest
        assertAlmostEq(expectedOpenInterest, totalOpenInterest.intoUint256(), 1, "open interest is not correct");

        // Create a second order
        changePrank({ msgSender: users.naruto.account });

        int128 secondSizeDelta = -sizeDelta;

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: secondSizeDelta
            })
        );

        uint256 newIndexPrice = isLong
            ? ud60x18(fuzzMarketConfig.mockUsdPrice).mul(ud60x18(priceShift)).intoUint256()
            : ud60x18(fuzzMarketConfig.mockUsdPrice).div(ud60x18(priceShift)).intoUint256();

        updateMockPriceFeed(fuzzMarketConfig.marketId, newIndexPrice);

        bytes memory secondMockSignedReport = getMockedSignedReport(fuzzMarketConfig.streamId, newIndexPrice);

        changePrank({ msgSender: marketOrderKeeper });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, secondMockSignedReport);

        // (longsOpenInterest, shortsOpenInterest, totalOpenInterest) =
        //     perpsEngine.getOpenInterest(fuzzMarketConfig.marketId);

        // expectedOpenInterest = 0;

        // // it should return longs open interest
        // assertAlmostEq(expectedOpenInterest, longsOpenInterest.intoUint256(), 1, "longs open interest is not
        // correct");

        // // it should return shorts open interest
        // assertAlmostEq(
        //     expectedOpenInterest, shortsOpenInterest.intoUint256(), 1, "shorts open interest is not correct"
        // );

        // // it should return total open interest
        // assertAlmostEq(expectedOpenInterest, totalOpenInterest.intoUint256(), 1, "open interest is not correct");
    }
}
