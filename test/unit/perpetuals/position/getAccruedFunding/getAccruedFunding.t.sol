// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";

// PRB Math dependencies
import { SD59x18, sd59x18 } from "@prb-math/SD59x18.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract Position_GetAccruedFunding_Unit_Test is Base_Test {
    using SafeCast for int256;

    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_WhenGetAccruedFundingIsCalled(
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

        Position.Data memory mockPosition = Position.Data({
            size: size,
            lastInteractionPrice: uint128(fuzzMarketConfig.mockUsdPrice),
            lastInteractionFundingFeePerUnit: lastInteractionFundingFeePerUnit
        });

        uint128 tradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        perpsEngine.exposed_update(tradingAccountId, fuzzMarketConfig.marketId, mockPosition);

        SD59x18 fundingFeePerUnitX18 = sd59x18(fundingFeePerUnit);
        SD59x18 netFundingFeePerUnit =
            fundingFeePerUnitX18.sub(sd59x18(mockPosition.lastInteractionFundingFeePerUnit));
        SD59x18 expectedAccruedFundingUsdX18 = sd59x18(mockPosition.size).mul(netFundingFeePerUnit);

        SD59x18 accruedFundingUsdX18 =
            perpsEngine.exposed_getAccruedFunding(tradingAccountId, fuzzMarketConfig.marketId, fundingFeePerUnitX18);

        // it should return the accrued funding usd
        assertEq(
            expectedAccruedFundingUsdX18.intoInt256(),
            accruedFundingUsdX18.intoInt256(),
            "Invalid accrued funding usd"
        );
    }
}
