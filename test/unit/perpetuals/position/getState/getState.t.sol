// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18 } from "@prb-math/SD59x18.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract Position_GetState_Unit_Test is Base_Test {
    using SafeCast for int256;

    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_WhenGetStateIsCalled(
        uint256 marketId,
        int128 fundingFeePerUnit,
        int128 lastInteractionFundingFeePerUnit,
        uint256 sizeAbs,
        bool isLong
    )
        external
    {
        changePrank({ msgSender: users.naruto.account });

        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeAbs =
            bound({ x: sizeAbs, min: uint256(fuzzMarketConfig.minTradeSize), max: uint256(fuzzMarketConfig.maxSkew) });
        int256 size = isLong ? int256(sizeAbs) : -int256(sizeAbs);

        uint128 tradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        Position.Data memory mockPosition = Position.Data({
            size: size,
            lastInteractionPrice: uint128(fuzzMarketConfig.mockUsdPrice),
            lastInteractionFundingFeePerUnit: lastInteractionFundingFeePerUnit
        });

        perpsEngine.exposed_update(tradingAccountId, fuzzMarketConfig.marketId, mockPosition);

        UD60x18 priceX18 = ud60x18(fuzzMarketConfig.mockUsdPrice);
        UD60x18 initialMarginRateX18 = ud60x18(fuzzMarketConfig.imr);
        UD60x18 maintenanceMarginRateX18 = ud60x18(fuzzMarketConfig.mmr);
        SD59x18 fundingFeePerUnitX18 = sd59x18(fundingFeePerUnit);

        Position.State memory state = perpsEngine.exposed_getState(
            tradingAccountId,
            fuzzMarketConfig.marketId,
            initialMarginRateX18,
            maintenanceMarginRateX18,
            priceX18,
            fundingFeePerUnitX18
        );

        // it should return the size
        assertEq(mockPosition.size, state.sizeX18.intoInt256(), "Invalid size");

        // it should return the notional value
        UD60x18 expectedNotionalValue = sd59x18(mockPosition.size).abs().intoUD60x18().mul(priceX18);
        assertEq(expectedNotionalValue.intoUint256(), state.notionalValueX18.intoUint256(), "Invalid notional value");

        // it should return the initial margin usd
        UD60x18 expectedInitialMarginUsdX18 = expectedNotionalValue.mul(initialMarginRateX18);
        assertEq(
            expectedInitialMarginUsdX18.intoUint256(),
            state.initialMarginUsdX18.intoUint256(),
            "Invalid initial margin usd"
        );

        // it should return the maintenance margin usd
        UD60x18 expectedMaintenanceMarginUsdX18 = expectedNotionalValue.mul(maintenanceMarginRateX18);
        assertEq(
            expectedMaintenanceMarginUsdX18.intoUint256(),
            state.maintenanceMarginUsdX18.intoUint256(),
            "Invalid maintenance margin usd"
        );

        // it should return the entry price
        assertEq(mockPosition.lastInteractionPrice, state.entryPriceX18.intoUint256(), "Invalid entry price");

        // it should return the accrued funding usd
        SD59x18 netFundingFeePerUnit =
            fundingFeePerUnitX18.sub(sd59x18(mockPosition.lastInteractionFundingFeePerUnit));
        SD59x18 expectedAccruedFundingUsdX18 = sd59x18(mockPosition.size).mul(netFundingFeePerUnit);
        assertEq(
            expectedAccruedFundingUsdX18.intoInt256(),
            state.accruedFundingUsdX18.intoInt256(),
            "Invalid accrued funding usd"
        );

        // it should return the unrealized pnl usd
        SD59x18 priceShift = priceX18.intoSD59x18().sub(ud60x18(mockPosition.lastInteractionPrice).intoSD59x18());
        SD59x18 expectedUnrealizedPnl = sd59x18(mockPosition.size).mul(priceShift);
        assertEq(
            expectedUnrealizedPnl.intoInt256(), state.unrealizedPnlUsdX18.intoInt256(), "Invalid unrealized pnl usd"
        );
    }
}
