// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18 } from "@prb-math/SD59x18.sol";

contract Position_GetUnrealizedPnl_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_WhenGetUnrealizedPnlIsCalled(
        uint256 marketId,
        uint256 sizeAbs,
        bool isLong,
        int128 lastInteractionFundingFeePerUnit
    )
        external
    {
        changePrank({ msgSender: users.naruto.account });

        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeAbs =
            bound({ x: sizeAbs, min: uint256(fuzzMarketConfig.minTradeSize), max: uint256(fuzzMarketConfig.maxSkew) });
        int256 size = isLong ? int256(sizeAbs) : -int256(sizeAbs);

        Position.Data memory mockPosition = Position.Data({
            size: size,
            lastInteractionPrice: uint128(fuzzMarketConfig.mockUsdPrice),
            lastInteractionFundingFeePerUnit: lastInteractionFundingFeePerUnit
        });

        uint128 tradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        perpsEngine.exposed_update(tradingAccountId, fuzzMarketConfig.marketId, mockPosition);

        UD60x18 newPrice = ud60x18(mockPosition.lastInteractionPrice).add(ud60x18(1e18));
        SD59x18 priceShift = newPrice.intoSD59x18().sub(ud60x18(mockPosition.lastInteractionPrice).intoSD59x18());
        SD59x18 expectedUnrealizedPnl = sd59x18(mockPosition.size).mul(priceShift);

        SD59x18 unrealizedPnl =
            perpsEngine.exposed_getUnrealizedPnl(tradingAccountId, fuzzMarketConfig.marketId, newPrice);

        // it should return the unrealized pnl usd
        assertEq(
            expectedUnrealizedPnl.intoInt256(), unrealizedPnl.intoInt256(), "expected unrealidzed pnl is not correct"
        );
    }
}
