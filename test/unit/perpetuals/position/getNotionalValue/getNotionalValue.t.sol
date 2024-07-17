// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { sd59x18 } from "@prb-math/SD59x18.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract Position_GetNotionalValue_Unit_Test is Base_Test {
    using SafeCast for int256;

    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_WhenGetNotionalValueIsCalled(
        uint256 marketId,
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

        UD60x18 expectedNotionalValue = sd59x18(mockPosition.size).abs().intoUD60x18().mul(priceX18);

        UD60x18 notionalValue =
            perpsEngine.exposed_getNotionalValue(tradingAccountId, fuzzMarketConfig.marketId, priceX18);

        // it should return the notional value
        assertEq(
            notionalValue.intoUint256(),
            expectedNotionalValue.intoUint256(),
            "notional value should be equal to expected notional value"
        );
    }
}
